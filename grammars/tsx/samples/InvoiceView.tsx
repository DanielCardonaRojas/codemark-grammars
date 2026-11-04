// Idiomatic TSX exercising the constructs this profile claims to understand.
//
// Authored for this repo. The TypeScript half mirrors grammars/typescript —
// interface, type, class, exported arrow function — so the two profiles can be
// compared line for line. The TSX half is what a .tsx file is actually for:
// function and arrow components returning JSX, hooks, event-handler closures
// and nested elements.
//
// Deliberately no `namespace`: as in the TypeScript sample, a bookmark inside
// one cannot be created today (codemark#246).
import { useMemo, useState } from "react";

export interface LineItem {
  sku: string;
  amount: number;
  taxable: boolean;
}

export interface Payable {
  pay(amount: number): boolean;
}

export type InvoiceProps = {
  lines: LineItem[];
  onPay: (total: number) => void;
};

export enum Status {
  Draft = "draft",
  Paid = "paid",
}

function formatMoney(value: number): string {
  return value.toFixed(2);
}

export function InvoiceView({ lines, onPay }: InvoiceProps) {
  const [status, setStatus] = useState(Status.Draft);

  const total = useMemo(() => {
    let sum = 0;
    for (const line of lines) {
      if (line.taxable) {
        sum += line.amount * 1.2;
      }
    }
    return sum;
  }, [lines]);

  const handlePay = () => {
    setStatus(Status.Paid);
    onPay(total);
  };

  return (
    <section className="invoice">
      <ul>
        {lines.map((line) => (
          <LineRow key={line.sku} line={line} />
        ))}
      </ul>
      <footer>
        <strong>{formatMoney(total)}</strong>
        <button disabled={status === Status.Paid} onClick={handlePay}>
          Pay
        </button>
      </footer>
    </section>
  );
}

export const LineRow = ({ line }: { line: LineItem }) => {
  const label = line.taxable ? "taxed" : "exempt";
  return (
    <li>
      {line.sku}: {formatMoney(line.amount)} ({label})
    </li>
  );
};

export class InvoiceStore implements Payable {
  private paid = new Set<string>();
  private lastPaid = "";

  pay(amount: number): boolean {
    return amount > 0;
  }

  markPaid(id: string): void {
    while (this.paid.size > 100) {
      this.paid.clear();
    }
    for (let i = 0; i < 3; i++) {
      console.debug("attempt", i);
    }
    this.paid.add(id);
    this.lastPaid = id;
  }
}
