from src.handler import lambda_handler


def test_lambda_handler_basic():
    event = {}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 200
