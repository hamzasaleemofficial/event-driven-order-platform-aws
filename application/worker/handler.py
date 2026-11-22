import json
import logging
import os
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation

import boto3
from aws_xray_sdk.core import patch
from botocore.exceptions import BotoCoreError, ClientError

# Enable X-Ray tracing for AWS SDK calls made through Boto3.
patch(["botocore"])

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def utc_now():
    """Return the current UTC timestamp."""
    return datetime.now(timezone.utc).isoformat()


def is_conditional_failure(error):
    """Check whether a DynamoDB conditional write failed."""
    return error.response["Error"]["Code"] == "ConditionalCheckFailedException"


def process_order(record, table, sns, topic_arn):
    """Process an order and publish its completion event."""
    order = json.loads(record["body"])

    order_id = order["order_id"]
    customer_id = order["customer_id"]
    items = order["items"]

    if not isinstance(order_id, str) or not order_id.strip():
        raise ValueError("Invalid order_id")

    if not isinstance(customer_id, str) or not customer_id.strip():
        raise ValueError("Invalid customer_id")

    if not isinstance(items, list) or not items:
        raise ValueError("Invalid items")

    # Normalize decimal prices from SQS before comparing with DynamoDB.
    for item in items:
        if not isinstance(item, dict):
            raise ValueError("Invalid item")

        if "price" in item:
            price = item["price"]

            if isinstance(price, str):
                try:
                    item["price"] = Decimal(price)
                except InvalidOperation:
                    raise ValueError("Invalid item price") from None

    # Support messages from the existing API, which does not
    # create the DynamoDB order before sending to SQS.
    now = utc_now()

    try:
        table.put_item(
            Item={
                "order_id": order_id,
                "customer_id": customer_id,
                "items": items,
                "status": "RECEIVED",
                "event_status": "pending",
                "created_at": now,
                "updated_at": now,
            },
            ConditionExpression="attribute_not_exists(order_id)",
        )
    except ClientError as error:
        if not is_conditional_failure(error):
            raise

    existing_order = table.get_item(
        Key={"order_id": order_id},
        ConsistentRead=True,
    ).get("Item")

    if existing_order is None:
        raise RuntimeError("Order could not be retrieved")

    # Reject messages whose contents do not match the stored order.
    if (
        existing_order.get("customer_id") != customer_id
        or existing_order.get("items") != items
    ):
        raise ValueError("SQS message does not match stored order")

    status = existing_order.get("status")
    event_status = existing_order.get("event_status")

    if status == "COMPLETED" and event_status == "published":
        logger.info(
            "Order already processed",
            extra={"order_id": order_id},
        )
        return

    if event_status != "pending":
        raise ValueError("Unexpected event_status")

    if status == "RECEIVED":
        table.update_item(
            Key={"order_id": order_id},
            UpdateExpression=("SET #status = :processing, updated_at = :updated_at"),
            ConditionExpression="#status = :received",
            ExpressionAttributeNames={"#status": "status"},
            ExpressionAttributeValues={
                ":processing": "PROCESSING",
                ":received": "RECEIVED",
                ":updated_at": utc_now(),
            },
        )

        status = "PROCESSING"

    if status == "PROCESSING":
        table.update_item(
            Key={"order_id": order_id},
            UpdateExpression=("SET #status = :completed, updated_at = :updated_at"),
            ConditionExpression="#status = :processing",
            ExpressionAttributeNames={"#status": "status"},
            ExpressionAttributeValues={
                ":completed": "COMPLETED",
                ":processing": "PROCESSING",
                ":updated_at": utc_now(),
            },
        )

    elif status != "COMPLETED":
        raise ValueError(f"Unexpected order status: {status}")

    event = {
        "event": "ORDER_COMPLETED",
        "order_id": order_id,
        "customer_id": customer_id,
        "items": items,
    }

    sns.publish(
        TopicArn=topic_arn,
        Message=json.dumps(event, default=str),
    )

    table.update_item(
        Key={"order_id": order_id},
        UpdateExpression=("SET event_status = :published, updated_at = :updated_at"),
        ConditionExpression=("#status = :completed AND event_status = :pending"),
        ExpressionAttributeNames={"#status": "status"},
        ExpressionAttributeValues={
            ":completed": "COMPLETED",
            ":published": "published",
            ":pending": "pending",
            ":updated_at": utc_now(),
        },
    )

    logger.info(
        "Order completed",
        extra={"order_id": order_id},
    )


def lambda_handler(event, context):
    """Process SQS records and report individual failures."""
    del context

    table_name = os.environ["ORDERS_TABLE_NAME"]
    topic_arn = os.environ["ORDER_EVENTS_TOPIC_ARN"]

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(table_name)
    sns = boto3.client("sns")

    failures = []

    for record in event["Records"]:
        try:
            process_order(record, table, sns, topic_arn)

        except (
            BotoCoreError,
            ClientError,
            KeyError,
            TypeError,
            ValueError,
            RuntimeError,
        ):
            message_id = record["messageId"]

            logger.exception(
                "Failed to process SQS message",
                extra={"message_id": message_id},
            )

            failures.append({"itemIdentifier": message_id})

    return {"batchItemFailures": failures}
