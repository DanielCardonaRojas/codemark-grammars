// Package invoice is idiomatic Go exercising the constructs this profile
// claims to understand.
//
// Authored for this repo. Construct coverage was cross-checked against
// tree-sitter-go's own test/corpus topics (declarations, statements,
// expressions) — read as a checklist, not copied.
//
// Every container kind below actually contains something: a type holds a
// struct body, methods hold statements, a function holds a closure. An empty
// declaration would teach the generator nothing about containment, which is
// the whole point of the snapshot check.
package invoice

import (
	"errors"
	"fmt"
)

// Version is a top-level constant — `const_declaration`.
const Version = "1.0.0"

// TaxRate is a package-level variable — `var_declaration`.
var TaxRate = 1.2

// ErrNotPayable is the sentinel this package returns for a settled invoice.
var ErrNotPayable = errors.New("invoice is not payable")

// Money is a defined type over a builtin. Parses as `type_declaration`
// wrapping a `type_spec`, both of which carry the `type` label and start on
// the same line — the collapse case codemark's breadcrumb walker handles.
type Money float64

// String formats the amount. A method on a non-struct named type.
func (m Money) String() string {
	return fmt.Sprintf("%.2f", float64(m))
}

// Stringer is an interface whose body holds a method spec — proves
// `type_declaration` is a real container.
type Stringer interface {
	String() string
}

// LineItem is a struct whose body holds field declarations.
type LineItem struct {
	Amount  Money
	Taxable bool
	Tags    []string
}

// Taxed applies the package tax rate when the line is taxable.
func (l LineItem) Taxed() Money {
	if l.Taxable {
		return Money(float64(l.Amount) * TaxRate)
	}

	return l.Amount
}

// Void reports whether the line carries no amount.
func (l LineItem) Void() bool {
	return l.Amount == 0
}

// Invoice is the aggregate the rest of this sample nests inside.
type Invoice struct {
	Lines []LineItem
	State string

	total Money
}

// New builds an Invoice from bare amounts, nesting a loop and a call.
func New(amounts []float64) *Invoice {
	items := make([]LineItem, 0, len(amounts))

	for _, amount := range amounts {
		items = append(items, LineItem{Amount: Money(amount), Taxable: amount > 100})
	}

	return &Invoice{Lines: items, State: "draft"}
}

// Payable reports whether this invoice still owes money.
func (i *Invoice) Payable() bool {
	return i.State != "paid"
}

// Compute totals the invoice. Its body holds a conditional and a range loop —
// the deepest chain among the methods here.
func (i *Invoice) Compute() (Money, error) {
	if !i.Payable() {
		return 0, ErrNotPayable
	}

	for _, line := range i.Lines {
		if line.Void() {
			continue
		}

		i.total += line.Taxed()
	}

	return i.total, nil
}

// Describe renders a label for the current state via a type switch and a
// select-free switch statement.
func (i *Invoice) Describe(verbose bool) string {
	var label string

	switch i.State {
	case "paid":
		label = "settled"
	case "draft", "pending":
		label = "open"
	default:
		label = "unknown"
	}

	if verbose {
		defer func() {
			fmt.Println(label)
		}()
	}

	return fmt.Sprintf("<Invoice %s %s>", i.total, label)
}

// Discount returns the total with a percentage off, computed by a closure
// nested inside this method — `func_literal` as a body you can bookmark
// inside.
func (i *Invoice) Discount(pct float64) Money {
	apply := func(amount Money) Money {
		// A function nested in a method: the deepest named chain in this file.
		return Money(float64(amount) * (1 - pct))
	}

	var sum Money
	for _, line := range i.Lines {
		sum += apply(line.Amount)
	}

	return sum
}

// Settle marks the invoice paid, returning the computed total.
func (i *Invoice) Settle() (Money, error) {
	total, err := i.Compute()
	if err != nil {
		return 0, fmt.Errorf("settle: %w", err)
	}

	i.State = "paid"

	return total, nil
}
