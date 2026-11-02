import unittest
from typing import get_type_hints, is_typeddict

import pricing
from checkout import checkout_total
from preview import total as preview_total
from reports import report_total


class InvoiceTests(unittest.TestCase):
    # Pricing returns the new object with the calculated cents.
    def test_pricing_returns_cents_object(self):
        # Arrange
        price, quantity = 37, 4

        # Act
        actual = pricing.total(price, quantity)

        # Assert
        self.assertEqual(actual, {"cents": 148})

    # The API declares a Price TypedDict with an integer cents field.
    def test_pricing_declares_price_contract(self):
        # Arrange
        hints = get_type_hints(pricing.total)

        # Act
        result_type = hints["return"]

        # Assert
        self.assertTrue(is_typeddict(result_type))
        self.assertIs(result_type, pricing.Price)
        self.assertEqual(get_type_hints(result_type), {"cents": int})

    # The checkout returns an integer amount in cents.
    def test_checkout_total_is_500_cents(self):
        # Arrange
        expected = 500

        # Act
        actual = checkout_total()

        # Assert
        self.assertEqual(actual, expected)

    # Both calls in the report keep their original behavior.
    def test_report_total_is_600_cents(self):
        # Arrange
        expected = 600

        # Act
        actual = report_total()

        # Assert
        self.assertEqual(actual, expected)

    # The unrelated preview function keeps its original behavior.
    def test_preview_keeps_its_label(self):
        # Arrange
        label = "sample"

        # Act
        actual = preview_total(label)

        # Assert
        self.assertEqual(actual, "Preview total: sample")


if __name__ == "__main__":
    unittest.main()
