from unittest.mock import Mock


def send_notification():
    print("Sending notification...")


def process_order(notification_function):
    notification_function()

    return "Order processed"


def test_process_order():
    fake_notification = Mock()

    result = process_order(fake_notification)

    assert result == "Order processed"

    fake_notification.assert_called_once()
