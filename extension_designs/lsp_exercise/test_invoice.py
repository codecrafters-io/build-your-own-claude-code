import unittest

from checkout import checkout_total
from preview import total as preview_total
from reports import report_total


class InvoiceTests(unittest.TestCase):
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
