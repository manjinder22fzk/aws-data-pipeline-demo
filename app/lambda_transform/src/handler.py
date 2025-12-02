import json
import os
import logging
from io import StringIO
import uuid
from typing import Optional

import boto3
import pandas as pd
from dateutil import parser as date_parser

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")

_config_cache = None


def _base_log_context(correlation_id: Optional[str] = None) -> dict:
    """
    Common fields we want on *every* structured log line.
    This makes querying/alerting easier.
    """
    ctx = {
        "pipeline": os.getenv("PROJECT", "money96-data-pipeline"),
        "environment": os.getenv("ENVIRONMENT", "dev"),
        "function": os.getenv(
            "AWS_LAMBDA_FUNCTION_NAME", "money96-data-pipeline-lambda"
        ),
    }
    if correlation_id:
        ctx["correlation_id"] = correlation_id
    return ctx


def _log_info(event: str, message: str, correlation_id: Optional[str] = None, **fields):
    payload = {
        **_base_log_context(correlation_id),
        "event": event,
        "level": "INFO",
        "message": message,
        **fields,
    }
    # Single-line JSON – perfect for CloudWatch Logs Insights and metric filters
    logger.info(json.dumps(payload))


def _log_error(
    event: str, message: str, correlation_id: Optional[str] = None, **fields
):
    payload = {
        **_base_log_context(correlation_id),
        "event": event,
        "level": "ERROR",
        "message": message,
        **fields,
    }
    logger.error(json.dumps(payload))


def _load_config():
    """
    Load config from AWS Secrets Manager.
    Falls back to environment variables for local/test usage.
    """
    global _config_cache
    if _config_cache is not None:
        return _config_cache

    # If running locally or env vars exist, use them
    raw_env = os.getenv("RAW_BUCKET_NAME")
    processed_env = os.getenv("PROCESSED_BUCKET_NAME")
    secret_name = os.getenv("CONFIG_SECRET_NAME")

    # Local override path (for unit tests or no secret)
    if raw_env and processed_env:
        _config_cache = {
            "raw_bucket": raw_env,
            "processed_bucket": processed_env,
            "processed_prefix": "processed/",
        }
        return _config_cache

    if not secret_name:
        # Keep backward-compatible error message so existing tests still pass
        raise RuntimeError("RAW_BUCKET_NAME or PROCESSED_BUCKET_NAME not set")

    client = boto3.client("secretsmanager")
    resp = client.get_secret_value(SecretId=secret_name)

    secret_data = json.loads(resp.get("SecretString", "{}"))

    # Final merged config
    _config_cache = {
        "raw_bucket": secret_data["raw_bucket"],
        "processed_bucket": secret_data["processed_bucket"],
        "processed_prefix": secret_data.get("processed_prefix", "processed/"),
    }

    return _config_cache


def transform_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    """
    Core business transformation logic.

    - Standardize order_date into ISO date (YYYY-MM-DD)
    - Drop rows with non-positive amount
    - Keep only valid statuses (PAID, PENDING)
    """
    required_columns = {"order_id", "order_date", "customer_id", "amount", "status"}
    missing = required_columns - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    # Parse and normalize dates
    def parse_date_safe(value):
        try:
            return date_parser.parse(str(value)).date().isoformat()
        except Exception:
            return None

    df = df.copy()
    df["order_date"] = df["order_date"].apply(parse_date_safe)
    df = df[df["order_date"].notna()]

    # Ensure numeric amount and > 0
    df["amount"] = pd.to_numeric(df["amount"], errors="coerce")
    df = df[df["amount"].notna()]
    df = df[df["amount"] > 0]

    # Filter statuses
    valid_statuses = {"PAID", "PENDING"}
    df = df[df["status"].isin(valid_statuses)]

    return df


def _get_bucket_and_key_from_event(event: dict) -> tuple[str, str]:
    """
    Extract bucket name and key from the event.

    Supports:
    - Classic S3 event (Records[0].s3.bucket.name / object.key)
    - EventBridge S3 Object Created event (detail.bucket.name / detail.object.key)
    """
    # 1) Direct S3 event notification format
    if "Records" in event and event["Records"]:
        record = event["Records"][0]
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]
        return bucket, key

    # 2) EventBridge S3 Object Created format
    detail = event.get("detail")
    if detail and "bucket" in detail and "object" in detail:
        bucket = detail["bucket"]["name"]
        key = detail["object"]["key"]
        return bucket, key

    # If we don’t recognize the structure:
    raise ValueError(
        "Unsupported event format. No S3 Records or detail.bucket/object found."
    )


def process_object(raw_bucket: str, processed_bucket: str, key: str) -> dict:
    """
    Read CSV from raw bucket, transform it, and write to processed bucket.

    Returns some metadata for logging / debugging.
    """
    logger.info("Processing object: bucket=%s, key=%s", raw_bucket, key)

    obj = s3.get_object(Bucket=raw_bucket, Key=key)
    body = obj["Body"].read().decode("utf-8")

    df_raw = pd.read_csv(StringIO(body))
    original_count = len(df_raw)

    df_processed = transform_dataframe(df_raw)
    processed_count = len(df_processed)

    csv_buffer = StringIO()
    df_processed.to_csv(csv_buffer, index=False)
    processed_key = _build_processed_key(key)

    s3.put_object(
        Bucket=processed_bucket,
        Key=processed_key,
        Body=csv_buffer.getvalue().encode("utf-8"),
    )

    logger.info(
        "Successfully processed file. original_count=%s, processed_count=%s, processed_key=%s",
        original_count,
        processed_count,
        processed_key,
    )

    return {
        "raw_bucket": raw_bucket,
        "processed_bucket": processed_bucket,
        "source_key": key,
        "processed_key": processed_key,
        "original_count": original_count,
        "processed_count": processed_count,
    }


def _build_processed_key(raw_key: str) -> str:
    """
    Build a key for the processed bucket.

    If raw key is like: raw/sales_2025...csv
    We can keep a similar structure under processed/ prefix.
    """
    # Simple version: just mirror the key under processed/
    # You could also include a date folder, etc.
    # If raw key already has folders, we keep the filename.
    filename = raw_key.split("/")[-1]
    return f"processed/{filename}"


def lambda_handler(event, context):
    """
    Lambda entry point.

    - Parses the event to find S3 bucket/key
    - Uses secret/env config for raw/processed buckets
    - Calls process_object to transform and write output
    """

    # Raw event log (good for debugging)
    logger.info("Received event: %s", json.dumps(event))

    # Correlation id – we try to base it on the event ID if present
    correlation_id = None
    if isinstance(event, dict):
        correlation_id = event.get("id") or str(uuid.uuid4())

    try:
        # -----------------------------------------
        # Load config (secret or env)
        # -----------------------------------------
        config = _load_config()
        raw_bucket_cfg = config["raw_bucket"]
        processed_bucket_cfg = config["processed_bucket"]

        # Event source bucket (should match raw_bucket)
        source_bucket, key = _get_bucket_and_key_from_event(event)
        # Now that we know bucket/key, refine correlation_id
        correlation_id = correlation_id or f"{source_bucket}/{key}"

        if source_bucket != raw_bucket_cfg:
            _log_info(
                event="bucket_mismatch",
                message="Event bucket != configured RAW bucket. Using event bucket.",
                correlation_id=correlation_id,
                event_bucket=source_bucket,
                configured_raw_bucket=raw_bucket_cfg,
            )

        result = process_object(
            raw_bucket=source_bucket,
            processed_bucket=processed_bucket_cfg,
            key=key,
        )

        dropped_count = result["original_count"] - result["processed_count"]

        # Structured success log – this is what we’ll build metrics on
        _log_info(
            event="transform_completed",
            message="File processed successfully",
            correlation_id=correlation_id,
            raw_bucket=result["raw_bucket"],
            processed_bucket=result["processed_bucket"],
            key=result["source_key"],
            processed_key=result["processed_key"],
            original_count=result["original_count"],
            processed_count=result["processed_count"],
            dropped_count=dropped_count,
            status="success",
        )

        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "message": "File processed successfully",
                    **result,
                    "dropped_count": dropped_count,
                }
            ),
        }

    except Exception as e:
        # Structured error log
        _log_error(
            event="transform_failed",
            message="Lambda processing failed",
            correlation_id=correlation_id,
            error_type=type(e).__name__,
            error_message=str(e),
        )

        # Extra: full stack trace for debugging in CloudWatch
        logger.exception(
            "Lambda failed processing event with correlation_id=%s", correlation_id
        )

        # Still raise so CloudWatch sees the error and retries / DLQ / alarms work
        raise
