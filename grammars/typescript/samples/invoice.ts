// Sample TypeScript exercising class / interface / enum / method nesting.
//
// Deliberately no `namespace`: a bookmark inside one makes the query generator
// emit a pattern that matches 0 nodes, so the bookmark can't be created at all.
// `internal_module` stays in the profile — it is the right container kind when
// that is fixed — but the sample can't exercise it today.
export interface Payable {
  pay(amount: number): boolean;
}

export enum Currency {
  USD = "usd",
  EUR = "eur",
}

export type LineLike = { amount: number; taxable: boolean };

export class Invoice implements Payable {
  private total = 0;

  constructor(private readonly lines: LineLike[]) {}

  compute(): number {
    for (const line of this.lines) {
      if (line.taxable) {
        this.addTaxed(line.amount);
      }
      this.total += line.amount;
    }
    return this.total;
  }

  private addTaxed(amount: number): void {
    this.total += amount * 0.2;
  }

  pay(amount: number): boolean {
    return amount > 0;
  }
}

export function formatMoney(value: number): string {
  return value.toFixed(2);
}

// A multi-line type alias has a body worth pinning, so `type` is a container.
export type Totals = {
  net: number;
  tax: number;
};

// The pattern the built-in profile anchored with export_statement and
// lexical_declaration: an exported const bound to an arrow function.
export const settle = (invoice: Invoice, attempts: number): boolean => {
  let tries = 0;
  while (tries < attempts) {
    tries = tries + 1;
    if (invoice.pay(tries)) {
      return true;
    }
  }
  for (let i = 0; i < attempts; i++) {
    console.warn("retry", i);
  }
  return false;
};
