import sys
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from notification import process_order


def test_process_order():
    with patch("notification.send_notification") as fake_notification:
        result = process_order()

        assert result == "Order processed"

        fake_notification.assert_called_once()
