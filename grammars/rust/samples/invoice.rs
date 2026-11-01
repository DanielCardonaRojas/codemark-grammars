//! Idiomatic Rust exercising the constructs this profile claims to understand.
//!
//! Authored for this repo. Construct coverage was cross-checked against
//! tree-sitter-rust's own test/corpus topics (declarations, expressions,
//! patterns) — read as a checklist, not copied.
//!
//! Every container kind below actually contains something: a module holds
//! types and impls, an impl holds methods, a method holds statements, a
//! function holds a closure. An empty declaration would teach the generator
//! nothing about containment, which is the whole point of the snapshot check.

use std::collections::HashMap;
use std::fmt;

/// A module-level constant — `const_item`.
pub const VERSION: &str = "1.0.0";

/// A module-level static — `static_item`, a distinct kind from `const_item`.
pub static TAX_RATE: f64 = 1.2;

/// A type alias — `type_item`.
pub type Money = f64;

/// A declarative macro. `macro_definition` is a landmark but never a
/// container: codemark cannot parse the macro body as Rust.
macro_rules! money {
    ($value:expr) => {
        format!("{:.2}", $value)
    };
}

/// A trait whose body holds a method signature and a defaulted method —
/// proves `trait_item` really contains declarations.
pub trait Payable {
    fn total(&self) -> Money;

    fn is_free(&self) -> bool {
        self.total() == 0.0
    }
}

/// An enum whose variants carry data.
#[derive(Debug, Clone, PartialEq)]
pub enum State {
    Draft,
    Pending { since: u64 },
    Paid(Money),
}

impl State {
    /// A method inside an impl inside nothing — the shallowest impl chain.
    pub fn label(&self) -> &'static str {
        match self {
            State::Draft => "open",
            State::Pending { .. } => "open",
            State::Paid(_) => "settled",
        }
    }
}

/// A struct with named fields.
#[derive(Debug, Clone)]
pub struct LineItem {
    pub amount: Money,
    pub taxable: bool,
    pub tags: Vec<String>,
}

impl LineItem {
    /// An associated function (no `self`) — still a `function_item`.
    pub fn new(amount: Money) -> Self {
        Self { amount, taxable: amount > 100.0, tags: Vec::new() }
    }

    /// A method whose body holds a conditional.
    pub fn taxed(&self) -> Money {
        if self.taxable {
            return self.amount * TAX_RATE;
        }

        self.amount
    }
}

impl Payable for LineItem {
    /// A trait impl — `impl_item` with a trait, a distinct shape from the
    /// inherent impl above.
    fn total(&self) -> Money {
        self.taxed()
    }
}

/// The aggregate the rest of this sample nests inside.
pub struct Invoice {
    lines: Vec<LineItem>,
    state: State,
    meta: HashMap<String, String>,
}

impl Invoice {
    pub fn new(amounts: &[f64]) -> Self {
        let mut lines = Vec::with_capacity(amounts.len());

        for amount in amounts {
            lines.push(LineItem::new(*amount));
        }

        Self { lines, state: State::Draft, meta: HashMap::new() }
    }

    /// A method whose body holds a loop and a conditional — the deepest
    /// control-flow chain among these methods.
    pub fn compute(&mut self) -> Result<Money, String> {
        if let State::Paid(total) = self.state {
            return Ok(total);
        }

        let mut total = 0.0;

        for line in &self.lines {
            if line.amount == 0.0 {
                continue;
            }

            total += line.taxed();
        }

        self.state = State::Paid(total);

        Ok(total)
    }

    /// A method holding a closure — `closure_expression` as a body you can
    /// bookmark inside.
    pub fn discounted(&self, pct: f64) -> Money {
        let apply = |amount: Money| -> Money {
            // A closure nested in a method: the deepest named chain here.
            amount * (1.0 - pct)
        };

        self.lines.iter().map(|l| apply(l.amount)).sum()
    }

    pub fn describe(&self) -> String {
        let label = match &self.state {
            State::Paid(total) => money!(total),
            other => other.label().to_string(),
        };

        format!("<Invoice {label}>")
    }

    pub fn tag(&mut self, key: &str, value: &str) {
        self.meta.insert(key.to_string(), value.to_string());
    }
}

impl fmt::Display for Invoice {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.describe())
    }
}

/// A module holding a type and an impl — proves `mod_item` is a container.
pub mod audit {
    use super::{Invoice, Money};

    /// A struct declared inside a module.
    pub struct Entry {
        pub delta: Money,
    }

    impl Entry {
        /// A method in an impl in a module: three container levels deep.
        pub fn record(invoice: &Invoice, delta: Money) -> Self {
            let _ = invoice;

            Self { delta }
        }

        /// A nested function inside a method — `function` as a container.
        pub fn normalized(&self) -> Money {
            fn clamp(value: Money) -> Money {
                if value < 0.0 {
                    return 0.0;
                }

                value
            }

            clamp(self.delta)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn computes_a_total() {
        let mut invoice = Invoice::new(&[50.0, 150.0]);

        assert!(invoice.compute().is_ok());
    }
}
