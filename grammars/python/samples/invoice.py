"""Idiomatic Python exercising the constructs this profile claims to understand.

Authored for this repo. Construct coverage was cross-checked against
tree-sitter-python's own test/corpus topics (statements, expressions,
pattern-matching) — read as a checklist, not copied.

Every container kind below actually contains something: a class holds methods
and a nested class, methods hold statements, a decorated definition wraps a
function. An empty declaration would teach the generator nothing about
containment, which is the whole point of the snapshot check.
"""

from __future__ import annotations

import functools
from dataclasses import dataclass, field
from typing import Iterable, Self

VERSION = "1.0.0"

TAX_RATE = 1.2


def money(value: float) -> str:
    """A module-level function — the shallowest named container."""
    return f"{value:.2f}"


class InvoiceError(Exception):
    """A class whose constructor nests statements inside it."""

    def __init__(self, invoice_id: int) -> None:
        self.invoice_id = invoice_id
        super().__init__(f"invoice {invoice_id} is not payable")


@dataclass
class LineItem:
    """A decorated class — `decorated_definition` wraps `class_definition`."""

    amount: float
    taxable: bool = False
    tags: list[str] = field(default_factory=list)

    def taxed(self) -> float:
        if self.taxable:
            return self.amount * TAX_RATE
        return self.amount

    def void(self) -> bool:
        return self.amount == 0.0


class Invoice:
    """A class holding methods, a nested class, and a decorated method."""

    def __init__(self, lines: Iterable[LineItem], state: str = "draft") -> None:
        self.lines = list(lines)
        self.state = state
        self._total = 0.0

    @property
    def payable(self) -> bool:
        return self.state != "paid"

    # A method whose body holds a loop, a conditional and a with-statement —
    # the deepest chain in this sample.
    def compute(self) -> float:
        if not self.payable:
            raise InvoiceError(id(self))

        for line in self.lines:
            if line.void():
                continue

            self._total += line.taxed()

        return self._total

    def describe(self, verbose: bool = False) -> str:
        match self.state:
            case "paid":
                label = "settled"
            case "draft" | "pending":
                label = "open"
            case _:
                label = "unknown"

        if verbose:
            with open("/dev/null", "w") as sink:
                print(label, file=sink)

        return f"<Invoice {money(self._total)} {label}>"

    @functools.cached_property
    def summary(self) -> str:
        """A decorated method inside a class — two wrappers deep."""
        parts = [money(line.amount) for line in self.lines]
        return ", ".join(parts)

    @classmethod
    def empty(cls) -> Self:
        return cls([])

    async def settle(self) -> float:
        """An async method — a distinct shape in the grammar."""
        total = self.compute()
        self.state = "paid"
        return total

    # A class nested inside a class — proves type-in-type containment.
    class Draft:
        """A nested class whose methods sit three container levels deep."""

        def __init__(self, owner: Invoice) -> None:
            self.owner = owner

        def promote(self) -> Invoice:
            try:
                self.owner.state = "pending"
            except AttributeError:
                self.owner.state = "draft"

            return self.owner

        def discount(self, pct: float) -> float:
            def apply(amount: float) -> float:
                """A function nested in a method — `function` as a container."""
                return amount * (1 - pct)

            return sum(apply(line.amount) for line in self.owner.lines)


def build(amounts: Iterable[float]) -> Invoice:
    """A module-level function nesting a loop and a call."""
    items = []

    for amount in amounts:
        items.append(LineItem(amount, taxable=amount > 100))

    return Invoice(items)
