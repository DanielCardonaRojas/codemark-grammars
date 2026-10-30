<?php

// Idiomatic PHP exercising the constructs this profile claims to understand.
//
// Authored for this repo. Construct coverage was cross-checked against
// tree-sitter-php's own test/corpus topics (class, declarations, statements,
// expressions) — read as a checklist, not copied.
//
// The BRACED namespace form is used deliberately. `namespace App\Billing;`
// (semicolon) does not enclose anything in the AST, so it can never appear in a
// breadcrumb — the old sample used it and recorded that as a known gap. The
// braced form does enclose, which turns `namespace_definition` from an
// unverifiable curation entry into an observed container and makes a four-level
// trail possible: namespace > class > method > statement.

namespace App\Billing {

    use InvalidArgumentException;
    use JsonSerializable;

    const DEFAULT_CURRENCY = 'EUR';

    enum InvoiceState: string
    {
        case Draft = 'draft';
        case Issued = 'issued';
        case Paid = 'paid';

        // A method on an enum, so `enum_declaration` contains a declaration
        // rather than only cases.
        public function isSettled(): bool
        {
            return $this === self::Paid;
        }
    }

    interface Payable
    {
        public function pay(float $amount): bool;

        public function currency(): string;
    }

    // A trait holding a method — PHP's unit of reuse, and a container kind the
    // old sample never exercised.
    trait Describable
    {
        public function describe(): string
        {
            return sprintf('%s in %s', static::class, $this->currency());
        }
    }

    abstract class Document implements Payable
    {
        public function __construct(protected readonly string $id)
        {
        }

        abstract public function total(): float;

        public function currency(): string
        {
            return DEFAULT_CURRENCY;
        }
    }

    final class InvoiceException extends InvalidArgumentException
    {
        public function __construct(
            private readonly string $invoiceId,
            string $message,
        ) {
            parent::__construct($message);
        }

        public function invoiceId(): string
        {
            return $this->invoiceId;
        }
    }

    final class Invoice extends Document implements JsonSerializable
    {
        use Describable;

        private const TAX_RATE = 1.2;

        /** @var list<LineItem> */
        private array $lines;

        private InvoiceState $state = InvoiceState::Draft;

        // Constructor property promotion is listed in the grammar's own corpus;
        // this one also has a body, which a parser test has no reason to add.
        public function __construct(string $id, array $lines = [])
        {
            parent::__construct($id);

            if ($lines === []) {
                throw new InvoiceException($id, 'an invoice needs at least one line');
            }

            $this->lines = $lines;
        }

        // A method whose body holds a foreach containing a match containing a
        // conditional — the deepest chain in this file.
        public function total(): float
        {
            $sum = 0.0;

            foreach ($this->lines as $line) {
                $sum += match (true) {
                    $line->isVoid() => 0.0,
                    $line->taxable => $line->amount * self::TAX_RATE,
                    default => $line->amount,
                };
            }

            return round($sum, 2);
        }

        public function pay(float $amount): bool
        {
            try {
                $remaining = $this->total() - $amount;
            } catch (InvoiceException $e) {
                error_log($e->getMessage());
                return false;
            } finally {
                $this->state = InvoiceState::Issued;
            }

            if ($remaining <= 0.0) {
                $this->state = InvoiceState::Paid;
            }

            return $this->state->isSettled();
        }

        public function jsonSerialize(): array
        {
            // A closure assigned to a variable, plus an arrow function passed
            // as an argument — the two anonymous-function spellings.
            $format = function (float $value): string {
                return number_format($value, 2);
            };

            return [
                'id' => $this->id,
                'state' => $this->state->value,
                'total' => $format($this->total()),
                'skus' => array_map(static fn (LineItem $l): string => $l->sku, $this->lines),
            ];
        }

        public static function draft(string $id): self
        {
            return new self($id, [new LineItem('placeholder', 0.0, false)]);
        }
    }

    final class LineItem
    {
        public function __construct(
            public readonly string $sku,
            public readonly float $amount,
            public readonly bool $taxable,
        ) {
        }

        public function isVoid(): bool
        {
            return $this->amount === 0.0;
        }
    }

    function formatMoney(float $value, string $currency = DEFAULT_CURRENCY): string
    {
        $formatted = number_format($value, 2);

        return "{$formatted} {$currency}";
    }

    // A generator function, so `yield` appears inside a loop inside a function.
    function eachTaxable(Invoice $invoice): iterable
    {
        foreach ($invoice->jsonSerialize()['skus'] as $index => $sku) {
            if ($sku === 'placeholder') {
                continue;
            }

            yield $index => $sku;
        }
    }
}
