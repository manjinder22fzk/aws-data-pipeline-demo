import json
import os
import logging
from io import StringIO

import boto3
import pandas as pd
from dateutil import parser as date_parser

logger = logging.getLogger()
logger.setLevel(logging.INFO)


s3 = boto3.client("s3")

_config_cache = None


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

    For now we assume a direct S3 event (Records[0].s3.bucket.name / object.key).

    Later, when we wire EventBridge, we can extend this to support that format too.
    """
    if "Records" in event and event["Records"]:
        record = event["Records"][0]
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]
        return bucket, key

    raise ValueError("Unsupported event format. No S3 Records found.")


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
    - Uses env vars to know RAW and PROCESSED bucket names
    - Calls process_object to transform and write output
    """

    logger.info("Received event: %s", json.dumps(event))

    # -----------------------------------------
    # NEW: load config (secret or env)
    # -----------------------------------------
    config = _load_config()

    raw_bucket_cfg = config["raw_bucket"]
    processed_bucket_cfg = config["processed_bucket"]

    # Event source bucket (should match raw_bucket)
    source_bucket, key = _get_bucket_and_key_from_event(event)

    if source_bucket != raw_bucket_cfg:
        logger.warning(
            "Event bucket (%s) != configured RAW bucket (%s). Using event bucket.",
            source_bucket,
            raw_bucket_cfg,
        )

    result = process_object(
        raw_bucket=source_bucket,
        processed_bucket=processed_bucket_cfg,
        key=key,
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "File processed successfully", **result}),
    }
