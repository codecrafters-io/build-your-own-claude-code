from pricing import total as invoice_total


def checkout_total() -> int:
    return invoice_total(250, 2)


if __name__ == "__main__":
    print(checkout_total())
