import json
import sys
from decimal import Decimal
from pathlib import Path
from unittest.mock import Mock, call, patch

import pytest
from botocore.exceptions import ClientError

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from handler import lambda_handler, validate_order

ORDER_ID = "0cf5daa9-90f6-4484-b625-196bdb910719"


def make_event(quantity=2):
    return {
        "requestContext": {"http": {"method": "POST"}},
        "body": json.dumps(
            {
                "customer_id": "customer-123",
                "items": [
                    {
                        "product_id": "laptop",
                        "quantity": quantity,
                    }
                ],
            }
        ),
    }


def make_get_event(order_id=ORDER_ID):
    return {
        "requestContext": {"http": {"method": "GET"}},
        "pathParameters": {"order_id": order_id},
    }


def make_client_error(operation):
    return ClientError(
        error_response={
            "Error": {
                "Code": "AccessDenied",
                "Message": "Access denied",
            }
        },
        operation_name=operation,
    )


def test_valid_order():
    order = {
        "customer_id": "customer-123",
        "items": [{"product_id": "laptop", "quantity": 2}],
    }

    assert validate_order(order) is None


def test_invalid_quantity():
    order = {
        "customer_id": "customer-123",
        "items": [{"product_id": "laptop", "quantity": -2}],
    }

    assert validate_order(order) == "items[0].quantity must be a positive integer"


@pytest.mark.parametrize(
    "order, expected_error",
    [
        (None, "Request body must be a JSON object"),
        ({}, "customer_id must be a non-empty string"),
        ({"customer_id": ""}, "customer_id must be a non-empty string"),
        (
            {"customer_id": "customer-123", "items": []},
            "items must be a non-empty list",
        ),
        (
            {
                "customer_id": "customer-123",
                "items": [{"product_id": "", "quantity": 2}],
            },
            "items[0].product_id must be a non-empty string",
        ),
        (
            {
                "customer_id": "customer-123",
                "items": [{"product_id": "laptop", "quantity": 0}],
            },
            "items[0].quantity must be a positive integer",
        ),
    ],
)
def test_invalid_orders(order, expected_error):
    assert validate_order(order) == expected_error


def test_lambda_handler_accepts_valid_order():
    fake_table = Mock()
    fake_dynamodb = Mock()
    fake_dynamodb.Table.return_value = fake_table
    fake_sqs = Mock()
    operations = Mock()

    fake_table.put_item.side_effect = lambda **kwargs: operations.save(**kwargs)
    fake_sqs.send_message.side_effect = lambda **kwargs: operations.enqueue(**kwargs)

    with (
        patch("handler.boto3.resource", return_value=fake_dynamodb),
        patch("handler.boto3.client", return_value=fake_sqs),
        patch.dict(
            "os.environ",
            {
                "ORDERS_QUEUE_URL": "https://example.com/test-orders",
                "ORDERS_TABLE_NAME": "test-orders",
            },
        ),
    ):
        response = lambda_handler(make_event(), None)

    assert response["statusCode"] == 202

    response_body = json.loads(response["body"])

    assert response_body["status"] == "accepted"
    assert "order_id" in response_body

    fake_dynamodb.Table.assert_called_once_with("test-orders")
    fake_table.put_item.assert_called_once()
    fake_sqs.send_message.assert_called_once()

    saved_order = fake_table.put_item.call_args.kwargs["Item"]
    sent_message = fake_sqs.send_message.call_args.kwargs

    assert saved_order["order_id"] == response_body["order_id"]
    assert saved_order["customer_id"] == "customer-123"
    assert saved_order["items"] == [{"product_id": "laptop", "quantity": 2}]
    assert saved_order["status"] == "RECEIVED"
    assert saved_order["event_status"] == "pending"
    assert saved_order["created_at"]
    assert saved_order["updated_at"] == saved_order["created_at"]

    assert (
        fake_table.put_item.call_args.kwargs["ConditionExpression"]
        == "attribute_not_exists(order_id)"
    )

    assert sent_message["QueueUrl"] == "https://example.com/test-orders"

    message_body = json.loads(sent_message["MessageBody"])

    assert message_body["order_id"] == saved_order["order_id"]
    assert message_body["customer_id"] == saved_order["customer_id"]
    assert message_body["items"] == saved_order["items"]

    assert operations.mock_calls == [
        call.save(
            Item=saved_order,
            ConditionExpression="attribute_not_exists(order_id)",
        ),
        call.enqueue(
            QueueUrl="https://example.com/test-orders",
            MessageBody=sent_message["MessageBody"],
        ),
    ]


def test_lambda_handler_accepts_decimal_price():
    """Decimal prices must work with both DynamoDB and SQS."""
    fake_table = Mock()
    fake_dynamodb = Mock()
    fake_dynamodb.Table.return_value = fake_table
    fake_sqs = Mock()

    event = {
        "requestContext": {"http": {"method": "POST"}},
        "body": json.dumps(
            {
                "customer_id": "customer-123",
                "items": [
                    {
                        "product_id": "laptop",
                        "quantity": 2,
                        "price": 25.00,
                    }
                ],
            }
        ),
    }

    with (
        patch("handler.boto3.resource", return_value=fake_dynamodb),
        patch("handler.boto3.client", return_value=fake_sqs),
        patch.dict(
            "os.environ",
            {
                "ORDERS_QUEUE_URL": "https://example.com/test-orders",
                "ORDERS_TABLE_NAME": "test-orders",
            },
        ),
    ):
        response = lambda_handler(event, None)

    # The API accepts the order.
    assert response["statusCode"] == 202

    # DynamoDB receives Decimal, not float.
    saved_order = fake_table.put_item.call_args.kwargs["Item"]
    assert saved_order["items"][0]["price"] == Decimal("25.0")
    assert isinstance(saved_order["items"][0]["price"], Decimal)

    # SQS receives valid JSON with the price represented as a string.
    sent_message = fake_sqs.send_message.call_args.kwargs
    message_body = json.loads(sent_message["MessageBody"])

    assert message_body["items"][0]["price"] == "25.0"


def test_lambda_handler_rejects_invalid_json():
    event = {
        "requestContext": {"http": {"method": "POST"}},
        "body": '{"customer_id": "customer-123"',
    }

    with (
        patch("handler.boto3.client") as fake_client,
        patch("handler.boto3.resource") as fake_resource,
    ):
        response = lambda_handler(event, None)

    assert response["statusCode"] == 400
    assert json.loads(response["body"]) == {"error": "Invalid JSON request body"}

    fake_client.assert_not_called()
    fake_resource.assert_not_called()


@pytest.mark.parametrize(
    "environment",
    [
        {
            "ORDERS_QUEUE_URL": "",
            "ORDERS_TABLE_NAME": "test-orders",
        },
        {
            "ORDERS_QUEUE_URL": "https://example.com/test-orders",
            "ORDERS_TABLE_NAME": "",
        },
    ],
)
def test_lambda_handler_missing_configuration(environment):
    with (
        patch.dict("os.environ", environment),
        patch("handler.boto3.client") as fake_client,
        patch("handler.boto3.resource") as fake_resource,
    ):
        response = lambda_handler(make_event(), None)

    assert response["statusCode"] == 500
    assert json.loads(response["body"]) == {"error": "Internal server error"}

    fake_client.assert_not_called()
    fake_resource.assert_not_called()


def test_lambda_handler_dynamodb_failure():
    fake_table = Mock()
    fake_table.put_item.side_effect = make_client_error("PutItem")

    fake_dynamodb = Mock()
    fake_dynamodb.Table.return_value = fake_table

    with (
        patch("handler.boto3.resource", return_value=fake_dynamodb),
        patch("handler.boto3.client") as fake_client,
        patch.dict(
            "os.environ",
            {
                "ORDERS_QUEUE_URL": "https://example.com/test-orders",
                "ORDERS_TABLE_NAME": "test-orders",
            },
        ),
    ):
        response = lambda_handler(make_event(), None)

    assert response["statusCode"] == 503
    assert json.loads(response["body"]) == {
        "error": "Order service temporarily unavailable"
    }

    fake_table.put_item.assert_called_once()
    fake_client.assert_not_called()


def test_lambda_handler_sqs_failure():
    fake_table = Mock()
    fake_dynamodb = Mock()
    fake_dynamodb.Table.return_value = fake_table

    fake_sqs = Mock()
    fake_sqs.send_message.side_effect = make_client_error("SendMessage")

    with (
        patch("handler.boto3.resource", return_value=fake_dynamodb),
        patch("handler.boto3.client", return_value=fake_sqs),
        patch.dict(
            "os.environ",
            {
                "ORDERS_QUEUE_URL": "https://example.com/test-orders",
                "ORDERS_TABLE_NAME": "test-orders",
            },
        ),
    ):
        response = lambda_handler(make_event(), None)

    assert response["statusCode"] == 503
    assert json.loads(response["body"]) == {
        "error": "Order service temporarily unavailable"
    }

    fake_table.put_item.assert_called_once()
    fake_sqs.send_message.assert_called_once()

    saved_order = fake_table.put_item.call_args.kwargs["Item"]

    assert saved_order["status"] == "RECEIVED"
    assert saved_order["event_status"] == "pending"

    fake_table.delete_item.assert_not_called()


def test_boolean_quantity_is_rejected():
    order = {
        "customer_id": "customer-123",
        "items": [{"product_id": "laptop", "quantity": True}],
    }

    assert validate_order(order) == "items[0].quantity must be a positive integer"


def test_multiple_valid_items():
    order = {
        "customer_id": "customer-123",
        "items": [
            {"product_id": "laptop", "quantity": 2},
            {"product_id": "keyboard", "quantity": 3},
            {"product_id": "monitor", "quantity": 1},
        ],
    }

    assert validate_order(order) is None


def test_invalid_second_item():
    order = {
        "customer_id": "customer-123",
        "items": [
            {"product_id": "laptop", "quantity": 2},
            {"product_id": "keyboard", "quantity": -3},
        ],
    }

    assert validate_order(order) == "items[1].quantity must be a positive integer"


def test_lambda_handler_rejects_invalid_order_without_aws_calls():
    with (
        patch("handler.boto3.client") as fake_client,
        patch("handler.boto3.resource") as fake_resource,
    ):
        response = lambda_handler(make_event(quantity=-2), None)

    assert response["statusCode"] == 400
    assert json.loads(response["body"]) == {
        "error": "items[0].quantity must be a positive integer"
    }

    fake_client.assert_not_called()
    fake_resource.assert_not_called()


def test_get_existing_order():
    order = {
        "order_id": ORDER_ID,
        "customer_id": "customer-123",
        "items": [{"product_id": "laptop", "quantity": 2}],
        "status": "COMPLETED",
        "event_status": "published",
        "created_at": "2026-11-11T17:02:37+00:00",
        "updated_at": "2026-11-11T17:02:41+00:00",
    }

    fake_table = Mock()
    fake_table.get_item.return_value = {"Item": order}

    fake_dynamodb = Mock()
    fake_dynamodb.Table.return_value = fake_table

    with (
        patch("handler.boto3.resource", return_value=fake_dynamodb),
        patch("handler.boto3.client") as fake_client,
        patch.dict("os.environ", {"ORDERS_TABLE_NAME": "test-orders"}),
    ):
        response = lambda_handler(make_get_event(), None)

    assert response["statusCode"] == 200
    assert json.loads(response["body"]) == order

    fake_table.get_item.assert_called_once_with(
        Key={"order_id": ORDER_ID},
        ConsistentRead=True,
    )

    fake_client.assert_not_called()


def test_get_missing_order():
    fake_table = Mock()
    fake_table.get_item.return_value = {}

    fake_dynamodb = Mock()
    fake_dynamodb.Table.return_value = fake_table

    with (
        patch("handler.boto3.resource", return_value=fake_dynamodb),
        patch.dict("os.environ", {"ORDERS_TABLE_NAME": "test-orders"}),
    ):
        response = lambda_handler(make_get_event(), None)

    assert response["statusCode"] == 404
    assert json.loads(response["body"]) == {"error": "Order not found"}


@pytest.mark.parametrize(
    "order_id",
    ["invalid-id", "", None],
)
def test_get_invalid_order_id(order_id):
    with patch("handler.boto3.resource") as fake_resource:
        response = lambda_handler(make_get_event(order_id), None)

    assert response["statusCode"] == 400
    assert json.loads(response["body"]) == {"error": "Invalid order_id"}
    fake_resource.assert_not_called()


def test_get_missing_path_parameters():
    event = {
        "requestContext": {"http": {"method": "GET"}},
    }

    with patch("handler.boto3.resource") as fake_resource:
        response = lambda_handler(event, None)

    assert response["statusCode"] == 400
    fake_resource.assert_not_called()


def test_get_missing_configuration():
    with (
        patch.dict("os.environ", {"ORDERS_TABLE_NAME": ""}),
        patch("handler.boto3.resource") as fake_resource,
    ):
        response = lambda_handler(make_get_event(), None)

    assert response["statusCode"] == 500
    assert json.loads(response["body"]) == {"error": "Internal server error"}

    fake_resource.assert_not_called()


def test_get_dynamodb_failure():
    fake_table = Mock()
    fake_table.get_item.side_effect = make_client_error("GetItem")

    fake_dynamodb = Mock()
    fake_dynamodb.Table.return_value = fake_table

    with (
        patch("handler.boto3.resource", return_value=fake_dynamodb),
        patch.dict("os.environ", {"ORDERS_TABLE_NAME": "test-orders"}),
    ):
        response = lambda_handler(make_get_event(), None)

    assert response["statusCode"] == 503
    assert json.loads(response["body"]) == {
        "error": "Order service temporarily unavailable"
    }


def test_unsupported_http_method():
    event = {
        "requestContext": {"http": {"method": "DELETE"}},
    }

    with (
        patch("handler.boto3.resource") as fake_resource,
        patch("handler.boto3.client") as fake_client,
    ):
        response = lambda_handler(event, None)

    assert response["statusCode"] == 405
    assert json.loads(response["body"]) == {"error": "Method not allowed"}

    fake_resource.assert_not_called()
    fake_client.assert_not_called()


def test_get_order_serializes_dynamodb_decimal():
    """DynamoDB Decimal quantities must be valid JSON numbers."""
    order = {
        "order_id": ORDER_ID,
        "customer_id": "customer-123",
        "items": [
            {
                "product_id": "laptop",
                "quantity": Decimal("2"),
            }
        ],
        "status": "COMPLETED",
    }

    fake_table = Mock()
    fake_table.get_item.return_value = {"Item": order}

    fake_dynamodb = Mock()
    fake_dynamodb.Table.return_value = fake_table

    with (
        patch("handler.boto3.resource", return_value=fake_dynamodb),
        patch.dict("os.environ", {"ORDERS_TABLE_NAME": "test-orders"}),
    ):
        response = lambda_handler(make_get_event(), None)

    assert response["statusCode"] == 200

    response_body = json.loads(response["body"])

    assert response_body["items"][0]["quantity"] == 2
    assert type(response_body["items"][0]["quantity"]) is int
