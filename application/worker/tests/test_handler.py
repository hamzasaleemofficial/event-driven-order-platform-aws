import json
from decimal import Decimal
from unittest.mock import Mock, patch

import pytest
from botocore.exceptions import ClientError

from application.worker.handler import lambda_handler, process_order


def make_record(message_id="message-123"):
    order = {
        "order_id": "order-123",
        "customer_id": "customer-123",
        "items": [{"product_id": "product-456", "quantity": 2}],
    }

    return {
        "messageId": message_id,
        "body": json.dumps(order),
    }


def make_order(status="RECEIVED", event_status="pending"):
    return {
        "order_id": "order-123",
        "customer_id": "customer-123",
        "items": [{"product_id": "product-456", "quantity": 2}],
        "status": status,
        "event_status": event_status,
    }


def conditional_check_error():
    return ClientError(
        {
            "Error": {
                "Code": "ConditionalCheckFailedException",
                "Message": "Conditional check failed",
            }
        },
        "PutItem",
    )


def sns_error():
    return ClientError(
        {
            "Error": {
                "Code": "InternalError",
                "Message": "SNS unavailable",
            }
        },
        "Publish",
    )


def make_table(status="RECEIVED", event_status="pending"):
    table = Mock()

    table.get_item.return_value = {"Item": make_order(status, event_status)}

    return table


def test_legacy_order_is_created_and_completed():
    table = make_table()
    sns = Mock()

    process_order(make_record(), table, sns, "test-topic-arn")

    table.put_item.assert_called_once()

    saved_order = table.put_item.call_args.kwargs["Item"]

    assert saved_order["status"] == "RECEIVED"
    assert saved_order["event_status"] == "pending"
    assert "created_at" in saved_order
    assert "updated_at" in saved_order

    assert table.update_item.call_count == 3

    first_update = table.update_item.call_args_list[0]
    second_update = table.update_item.call_args_list[1]

    assert (
        first_update.kwargs["ExpressionAttributeValues"][":processing"] == "PROCESSING"
    )
    assert (
        second_update.kwargs["ExpressionAttributeValues"][":completed"] == "COMPLETED"
    )

    sns.publish.assert_called_once()

    event = json.loads(sns.publish.call_args.kwargs["Message"])

    assert event["event"] == "ORDER_COMPLETED"
    assert event["order_id"] == "order-123"


def test_api_created_order_is_processed():
    table = make_table()
    sns = Mock()

    table.put_item.side_effect = conditional_check_error()

    process_order(make_record(), table, sns, "test-topic-arn")

    table.get_item.assert_called_once_with(
        Key={"order_id": "order-123"},
        ConsistentRead=True,
    )

    assert table.update_item.call_count == 3
    sns.publish.assert_called_once()


def test_api_created_order_with_decimal_price_is_processed():
    """SQS string prices must match DynamoDB Decimal prices."""
    table = make_table()
    sns = Mock()

    # Simulate an order already created by the API.
    table.put_item.side_effect = conditional_check_error()

    # DynamoDB returns prices as Decimal.
    stored_order = table.get_item.return_value["Item"]
    stored_order["items"][0]["price"] = Decimal("25.00")

    # SQS JSON contains the same price as a string.
    record = make_record()
    message = json.loads(record["body"])
    message["items"][0]["price"] = "25.00"
    record["body"] = json.dumps(message)

    process_order(record, table, sns, "test-topic-arn")

    # The Worker should complete processing and publish the event.
    assert table.update_item.call_count == 3
    sns.publish.assert_called_once()


def test_mismatched_decimal_price_is_rejected():
    """Reject an SQS message whose price differs from DynamoDB."""
    table = make_table()
    sns = Mock()

    table.put_item.side_effect = conditional_check_error()

    # DynamoDB contains the original price.
    stored_order = table.get_item.return_value["Item"]
    stored_order["items"][0]["price"] = Decimal("25.00")

    # SQS contains a different price.
    record = make_record()
    message = json.loads(record["body"])
    message["items"][0]["price"] = "30.00"
    record["body"] = json.dumps(message)

    with pytest.raises(ValueError, match="does not match"):
        process_order(record, table, sns, "test-topic-arn")

    # Invalid messages must not modify the order or publish events.
    table.update_item.assert_not_called()
    sns.publish.assert_not_called()


def test_processing_order_can_resume():
    table = make_table(status="PROCESSING")
    sns = Mock()

    table.put_item.side_effect = conditional_check_error()

    process_order(make_record(), table, sns, "test-topic-arn")

    # Complete the order, then mark the SNS event published.
    assert table.update_item.call_count == 2
    sns.publish.assert_called_once()


def test_completed_order_with_pending_event_retries_sns():
    table = make_table(status="COMPLETED")
    sns = Mock()

    table.put_item.side_effect = conditional_check_error()

    process_order(make_record(), table, sns, "test-topic-arn")

    # No status transition is needed.
    assert table.update_item.call_count == 1
    sns.publish.assert_called_once()


def test_completed_published_order_is_skipped():
    table = make_table(
        status="COMPLETED",
        event_status="published",
    )
    sns = Mock()

    table.put_item.side_effect = conditional_check_error()

    process_order(make_record(), table, sns, "test-topic-arn")

    sns.publish.assert_not_called()
    table.update_item.assert_not_called()


def test_inconsistent_published_order_is_rejected():
    table = make_table(
        status="RECEIVED",
        event_status="published",
    )
    sns = Mock()

    table.put_item.side_effect = conditional_check_error()

    with pytest.raises(ValueError, match="Unexpected event_status"):
        process_order(make_record(), table, sns, "test-topic-arn")

    sns.publish.assert_not_called()


def test_mismatched_order_is_rejected():
    table = make_table()
    sns = Mock()

    table.put_item.side_effect = conditional_check_error()

    table.get_item.return_value["Item"]["customer_id"] = "other-customer"

    with pytest.raises(ValueError, match="does not match"):
        process_order(make_record(), table, sns, "test-topic-arn")

    sns.publish.assert_not_called()
    table.update_item.assert_not_called()


def test_sns_failure_leaves_event_pending():
    table = make_table()
    sns = Mock()

    sns.publish.side_effect = sns_error()

    with pytest.raises(ClientError):
        process_order(make_record(), table, sns, "test-topic-arn")

    # Only the PROCESSING and COMPLETED updates occur.
    # The event must not be marked published.
    assert table.update_item.call_count == 2


def test_sns_failure_then_successful_retry():
    table = make_table()
    sns = Mock()

    sns.publish.side_effect = [
        sns_error(),
        {"MessageId": "sns-message-123"},
    ]

    with pytest.raises(ClientError):
        process_order(make_record(), table, sns, "test-topic-arn")

    # Simulate DynamoDB's state after the first attempt.
    table.put_item.side_effect = conditional_check_error()
    table.get_item.return_value = {"Item": make_order(status="COMPLETED")}

    process_order(make_record(), table, sns, "test-topic-arn")

    assert sns.publish.call_count == 2

    # Two status updates from the first attempt,
    # followed by the event-status update on retry.
    assert table.update_item.call_count == 3

    last_update = table.update_item.call_args.kwargs

    assert last_update["ExpressionAttributeValues"][":published"] == "published"


@patch.dict(
    "os.environ",
    {
        "ORDERS_TABLE_NAME": "test-orders",
        "ORDER_EVENTS_TOPIC_ARN": "test-topic-arn",
    },
)
@patch("application.worker.handler.boto3")
def test_lambda_handler_success(mock_boto3):
    table = make_table()

    mock_boto3.resource.return_value.Table.return_value = table

    response = lambda_handler(
        {"Records": [make_record()]},
        None,
    )

    assert response == {"batchItemFailures": []}
    assert table.update_item.call_count == 3
    mock_boto3.client.return_value.publish.assert_called_once()


@patch.dict(
    "os.environ",
    {
        "ORDERS_TABLE_NAME": "test-orders",
        "ORDER_EVENTS_TOPIC_ARN": "test-topic-arn",
    },
)
@patch("application.worker.handler.boto3")
def test_lambda_handler_reports_failed_message(mock_boto3):
    table = make_table()

    table.put_item.side_effect = ClientError(
        {
            "Error": {
                "Code": "AccessDeniedException",
                "Message": "Access denied",
            }
        },
        "PutItem",
    )

    mock_boto3.resource.return_value.Table.return_value = table

    response = lambda_handler(
        {"Records": [make_record("failed-message")]},
        None,
    )

    assert response == {
        "batchItemFailures": [
            {"itemIdentifier": "failed-message"},
        ]
    }


@patch.dict(
    "os.environ",
    {
        "ORDERS_TABLE_NAME": "test-orders",
        "ORDER_EVENTS_TOPIC_ARN": "test-topic-arn",
    },
)
@patch("application.worker.handler.boto3")
def test_lambda_handler_handles_partial_batch_failure(mock_boto3):
    table = make_table()
    sns = Mock()

    table.put_item.side_effect = [
        None,
        ClientError(
            {
                "Error": {
                    "Code": "AccessDeniedException",
                    "Message": "Access denied",
                }
            },
            "PutItem",
        ),
    ]

    mock_boto3.resource.return_value.Table.return_value = table
    mock_boto3.client.return_value = sns

    response = lambda_handler(
        {
            "Records": [
                make_record("successful-message"),
                make_record("failed-message"),
            ]
        },
        None,
    )

    assert response == {
        "batchItemFailures": [
            {"itemIdentifier": "failed-message"},
        ]
    }

    assert sns.publish.call_count == 1
