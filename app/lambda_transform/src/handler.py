import json
import os

def lambda_handler(event, context):
    """
    Temporary stub.
    Later we will:
    - Parse S3 event (raw bucket object created)
    - Read CSV from raw bucket
    - Transform and write to processed bucket
    """
    print("Event received:", json.dumps(event))

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Lambda is deployed and running",
                "raw_bucket": os.getenv("RAW_BUCKET_NAME"),
                "processed_bucket": os.getenv("PROCESSED_BUCKET_NAME"),
                "env": os.getenv("ENVIRONMENT"),
            }
        ),
    }
