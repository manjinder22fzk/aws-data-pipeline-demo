import json


def lambda_handler(event, context):
    """
    Placeholder Lambda handler.
    In later phases, this will:
    - Parse the S3 event
    - Read raw CSV from S3
    - Apply transformations
    - Write transformed CSV to processed bucket
    """
    print("Received event:", json.dumps(event))
    return {"statusCode": 200, "body": json.dumps({"message": "OK"})}
