import os
import uuid
from datetime import datetime
import boto3
import pandas as pd
from faker import Faker

fake = Faker()


def generate_fake_sales_data(num_rows: int = 1000) -> pd.DataFrame:
    records = []
    for _ in range(num_rows):
        records.append(
            {
                "order_id": str(uuid.uuid4()),
                "order_date": fake.date_between(
                    start_date="-30d", end_date="today"
                ).isoformat(),
                "customer_id": fake.random_int(min=1, max=10000),
                "amount": round(
                    fake.pyfloat(min_value=1, max_value=500, right_digits=2), 2
                ),
                "currency": "USD",
                "status": fake.random_element(["PAID", "PENDING", "CANCELLED"]),
            }
        )
    return pd.DataFrame(records)


def upload_to_s3(df: pd.DataFrame, bucket: str, prefix: str = "raw/") -> str:
    s3 = boto3.client("s3")
    ts = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    key = f"{prefix}sales_{ts}.csv"
    csv_body = df.to_csv(index=False)
    s3.put_object(Bucket=bucket, Key=key, Body=csv_body)
    return key


if __name__ == "__main__":
    bucket = os.getenv("RAW_BUCKET_NAME", "replace-me-dev-raw")
    df = generate_fake_sales_data(1000)
    key = upload_to_s3(df, bucket)
    print(f"Uploaded fake data to s3://{bucket}/{key}")
