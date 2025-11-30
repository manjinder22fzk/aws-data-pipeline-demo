import json
import os

import pandas as pd

from src.handler import transform_dataframe, lambda_handler


def test_transform_dataframe_filters_and_normalizes():
    data = {
        "order_id": ["1", "2", "3", "4"],
        "order_date": ["2025-01-01", "2025/01/02", "bad-date", "2025-01-04"],
        "customer_id": [10, 20, 30, 40],
        "amount": [100, -5, 50, 0],
        "status": ["PAID", "PENDING", "CANCELLED", "PAID"],
    }
    df = pd.DataFrame(data)

    df_out = transform_dataframe(df)

    # Expected:
    # - row 1: valid
    # - row 2: negative amount -> dropped
    # - row 3: bad date + CANCELLED -> dropped
    # - row 4: amount 0 -> dropped
    assert len(df_out) == 1
    row = df_out.iloc[0]

    assert row["order_id"] == "1"
    assert row["status"] == "PAID"
    assert row["amount"] == 100
    # date normalized
    assert row["order_date"] == "2025-01-01"


def test_lambda_handler_missing_env_vars_raises(monkeypatch):
    # Clear env vars
    monkeypatch.delenv("RAW_BUCKET_NAME", raising=False)
    monkeypatch.delenv("PROCESSED_BUCKET_NAME", raising=False)

    event = {}
    try:
        lambda_handler(event, None)
        assert False, "Expected RuntimeError due to missing env vars"
    except RuntimeError as e:
        assert "RAW_BUCKET_NAME or PROCESSED_BUCKET_NAME not set" in str(e)
