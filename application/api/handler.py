import json
import logging
import os
import uuid
from datetime import datetime, timezone
from decimal import Decimal

import boto3
from botocore.exceptions import BotoCoreError, ClientError
from aws_xray_sdk.core import patch

# Enable X-Ray tracing for AWS SDK calls made through Boto3.
patch(["botocore"])

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def serialize_decimal(value):
    """Convert DynamoDB Decimal values into JSON-compatible numbers."""
    if isinstance(value, Decimal):
        if value == value.to_integral_value():
            return int(value)
        return float(value)

    raise TypeError(f"Object of type {type(value).__name__} is not JSON serializable")

def create_response(status_code, body):
    """Build an API Gateway-compatible HTTP response."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
        },
        "body": json.dumps(body, default=serialize_decimal),
    }


def validate_order(order):
    """Validate the required fields in an order request."""
    if not isinstance(order, dict):
        return "Request body must be a JSON object"

    customer_id = order.get("customer_id")
    if not isinstance(customer_id, str) or not customer_id.strip():
        return "customer_id must be a non-empty string"

    items = order.get("items")
    if not isinstance(items, list) or not items:
        return "items must be a non-empty list"

    for index, item in enumerate(items):
        if not isinstance(item, dict):
            return f"items[{index}] must be an object"

        product_id = item.get("product_id")
        if not isinstance(product_id, str) or not product_id.strip():
            return f"items[{index}].product_id must be a non-empty string"

        quantity = item.get("quantity")
        if type(quantity) is not int or quantity <= 0:
            return f"items[{index}].quantity must be a positive integer"

    return None


def utc_now():
    """Return the current UTC timestamp."""
    return datetime.now(timezone.utc).isoformat()


def create_order(event):
    """Create an order in DynamoDB and enqueue it for processing."""
    try:
        body = json.loads(event.get("body") or "", parse_float=Decimal)
    except (TypeError, ValueError):
        return create_response(400, {"error": "Invalid JSON request body"})

    validation_error = validate_order(body)

    if validation_error:
        return create_response(400, {"error": validation_error})

    queue_url = os.environ.get("ORDERS_QUEUE_URL")
    table_name = os.environ.get("ORDERS_TABLE_NAME")

    if not queue_url or not table_name:
        logger.error("Required order service environment variables are missing")
        return create_response(500, {"error": "Internal server error"})

    order_id = str(uuid.uuid4())
    now = utc_now()

    message = {
        "order_id": order_id,
        "customer_id": body["customer_id"],
        "items": body["items"],
    }

    order_item = {
        **message,
        "status": "RECEIVED",
        "event_status": "pending",
        "created_at": now,
        "updated_at": now,
    }

    try:
        dynamodb = boto3.resource("dynamodb")
        table = dynamodb.Table(table_name)

        table.put_item(
            Item=order_item,
            ConditionExpression="attribute_not_exists(order_id)",
        )

    except (BotoCoreError, ClientError):
        logger.exception("Failed to save order: %s", order_id)
        return create_response(
            503,
            {"error": "Order service temporarily unavailable"},
        )

    try:
        sqs = boto3.client("sqs")

        sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(message, default=str),
        )

    except (BotoCoreError, ClientError):
        logger.exception(
            "Failed to enqueue order %s; DynamoDB record retained",
            order_id,
        )
        return create_response(
            503,
            {"error": "Order service temporarily unavailable"},
        )

    logger.info(
        "Order accepted",
        extra={"order_id": order_id},
    )

    return create_response(
        202,
        {
            "order_id": order_id,
            "status": "accepted",
        },
    )


def get_order(event):
    """Retrieve an order from DynamoDB by its ID."""
    path_parameters = event.get("pathParameters") or {}
    order_id = path_parameters.get("order_id")

    try:
        if not isinstance(order_id, str):
            raise ValueError("Missing order ID")

        uuid.UUID(order_id)

    except ValueError:
        return create_response(400, {"error": "Invalid order_id"})

    table_name = os.environ.get("ORDERS_TABLE_NAME")

    if not table_name:
        logger.error("ORDERS_TABLE_NAME environment variable is missing")
        return create_response(500, {"error": "Internal server error"})

    try:
        dynamodb = boto3.resource("dynamodb")
        table = dynamodb.Table(table_name)

        result = table.get_item(
            Key={"order_id": order_id},
            ConsistentRead=True,
        )

    except (BotoCoreError, ClientError):
        logger.exception("Failed to retrieve order: %s", order_id)
        return create_response(
            503,
            {"error": "Order service temporarily unavailable"},
        )

    order = result.get("Item")

    if not order:
        return create_response(404, {"error": "Order not found"})

    return create_response(200, order)


def lambda_handler(event, context):
    """Route API Gateway HTTP API requests."""
    del context

    method = (
        event.get("requestContext", {})
        .get("http", {})
        .get("method")
    )

    if method == "POST":
        return create_order(event)

    if method == "GET":
        return get_order(event)

    return create_response(405, {"error": "Method not allowed"})