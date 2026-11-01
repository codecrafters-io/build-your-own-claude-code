from pricing import total


def report_total() -> int:
    return total(250, 2) + total(100, 1)
