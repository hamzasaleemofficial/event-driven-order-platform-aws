def calculate_total(price, quantity):
    return price * quantity


def test_calculate_total():
    result = calculate_total(500, 3)

    assert result == 1500
