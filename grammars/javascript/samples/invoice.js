/**
 * Idiomatic JavaScript exercising the constructs this profile claims to
 * understand.
 *
 * Authored for this repo. Construct coverage was cross-checked against
 * tree-sitter-javascript's own test/corpus topics (declarations, statements,
 * expressions) — read as a checklist, not copied.
 *
 * Every container kind below actually contains something: a class holds
 * methods, a method holds statements, a function holds a nested function and
 * an arrow function. An empty declaration would teach the generator nothing
 * about containment, which is the whole point of the snapshot check.
 */

import { readFile } from "node:fs/promises";

export const VERSION = "1.0.0";

/** Reads a saved invoice. Keeps the import above load-bearing. */
export async function load(path) {
  const raw = await readFile(path, "utf8");

  return JSON.parse(raw);
}

const TAX_RATE = 1.2;

/** A plain function declaration — the shallowest named container. */
export function money(value) {
  return value.toFixed(2);
}

/**
 * A generator function — `generator_function_declaration`, a distinct node
 * kind from `function_declaration`.
 */
export function* counter(limit) {
  for (let i = 0; i < limit; i += 1) {
    yield i;
  }
}

/** An arrow function bound to a const. Labelled `function`, no name field. */
export const asCents = (value) => Math.round(value * 100);

/** A class whose constructor nests statements. */
export class InvoiceError extends Error {
  constructor(invoiceId) {
    super(`invoice ${invoiceId} is not payable`);
    this.invoiceId = invoiceId;
  }
}

/** A class holding a field, methods, a getter, a static method and a nested
 *  arrow function. */
export class Invoice {
  /** A class field — `field_definition`. */
  state = "draft";

  static #count = 0;

  constructor(lines) {
    this.lines = [...lines];
    this.total = 0;
    Invoice.#count += 1;
  }

  /** A getter — `method_definition` with a `get` keyword. */
  get payable() {
    return this.state !== "paid";
  }

  /**
   * A method whose body holds a conditional and a loop — the deepest
   * control-flow chain among these methods.
   */
  compute() {
    if (!this.payable) {
      throw new InvoiceError(1);
    }

    for (const line of this.lines) {
      if (line.amount === 0) {
        continue;
      }

      this.total += line.taxable ? line.amount * TAX_RATE : line.amount;
    }

    return this.total;
  }

  /** A method holding an arrow function — a bookmarkable nested body. */
  discounted(pct) {
    const apply = (amount) => {
      // An arrow function nested in a method: the deepest named chain here.
      return amount * (1 - pct);
    };

    return this.lines.reduce((sum, line) => sum + apply(line.amount), 0);
  }

  /** A method using a switch. */
  describe() {
    switch (this.state) {
      case "paid":
        return "settled";
      case "draft":
        return "open";
      default:
        return "unknown";
    }
  }

  /** An async method — `method_definition` with `async`. */
  async settle() {
    try {
      this.state = "paid";
    } catch (err) {
      this.state = "draft";
    }

    return this.total;
  }

  /** A static method. */
  static count() {
    return Invoice.#count;
  }
}

/**
 * A module-level function nesting a function declaration and an object
 * literal with a method — proves function-in-function containment.
 */
export function build(amounts) {
  function toLine(amount) {
    // A function nested in a function.
    return { amount, taxable: amount > 100 };
  }

  const helpers = {
    /** A method inside an object literal — also a `method_definition`. */
    sum(lines) {
      return lines.reduce((acc, l) => acc + l.amount, 0);
    },
  };

  const lines = amounts.map(toLine);

  return { invoice: new Invoice(lines), total: helpers.sum(lines) };
}

export default Invoice;
