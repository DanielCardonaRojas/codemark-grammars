<?php
// Sample PHP exercising class > method nesting. Note the semicolon form of
// `namespace` does not enclose the class in the AST, so it never appears in a
// breadcrumb; a braced `namespace X { ... }` would.
namespace App\Billing;

class Invoice
{
    private array $lines = [];

    public function __construct(array $lines)
    {
        $this->lines = $lines;
    }

    public function total(): float
    {
        $sum = 0.0;
        foreach ($this->lines as $line) {
            if ($line->taxable) {
                $sum += $line->amount * 1.2;
            } else {
                $sum += $line->amount;
            }
        }
        return $sum;
    }

    public static function empty(): self
    {
        return new self([]);
    }
}

interface Payable
{
    public function pay(float $amount): bool;
}

function formatMoney(float $v): string
{
    return number_format($v, 2);
}
