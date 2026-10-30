// Idiomatic Scala exercising the constructs this profile claims to understand.
//
// Authored for this repo. Construct coverage was cross-checked against
// tree-sitter-scala's own test/corpus topics (definitions, expressions,
// patterns, types) — read as a checklist, not copied.
//
// The BRACED package form is used deliberately. `package app.billing` on its
// own line parses as a `package_clause` that encloses nothing, so it could
// never appear in a breadcrumb; the braced form does enclose, which makes
// `package_clause` an observed container and allows a four-level trail:
// package > object/class > def > statement.

package app.billing {

  import scala.util.{Failure, Success, Try}

  type Cents = Long

  sealed trait InvoiceState

  object InvoiceState {
    case object Draft extends InvoiceState
    case object Issued extends InvoiceState
    case object Paid extends InvoiceState
  }

  final case class LineItem(sku: String, amount: Double, taxable: Boolean) {
    def isVoid: Boolean = amount == 0.0

    def taxed(rate: Double): Double = amount * rate
  }

  final class InvoiceException(val invoiceId: String, message: String)
      extends RuntimeException(message)

  trait Payable {
    def pay(amount: Double): Boolean

    // A concrete method in a trait, so the trait contains a definition rather
    // than only an abstract signature.
    def describe: String = s"payable: ${getClass.getSimpleName}"
  }

  class Invoice(val id: String, val lines: List[LineItem]) extends Payable {
    private val TaxRate: Double = 1.2

    private var total: Double = 0.0
    private var state: InvoiceState = InvoiceState.Draft

    // A method whose body holds a for comprehension containing a pattern match
    // containing a guard — the deepest chain in this file.
    def compute(): Double = {
      total = 0.0

      for (line <- lines if !line.isVoid) {
        total += (line match {
          case LineItem(_, amount, true) => amount * TaxRate
          case LineItem(_, amount, false) if amount > 100.0 =>
            val discounted = amount * 0.9
            discounted
          case other => other.amount
        })
      }

      // A local def: a definition nested inside a method body.
      def rounded(value: Double): Double = BigDecimal(value)
        .setScale(2, BigDecimal.RoundingMode.HALF_UP)
        .toDouble

      total = rounded(total)
      total
    }

    def pay(amount: Double): Boolean = {
      Try(compute() - amount) match {
        case Success(remaining) if remaining <= 0.0 =>
          state = InvoiceState.Paid
          true
        case Success(_) =>
          state = InvoiceState.Issued
          false
        case Failure(error) =>
          throw new InvoiceException(id, error.getMessage)
      }
    }

    // A class nested inside a class, holding its own method — proves
    // type-in-type containment.
    class Summary(val label: String) {
      def render(): String = {
        val suffix = if (lines.sizeIs == 1) "line" else "lines"
        s"$label: ${lines.size} $suffix"
      }
    }

    override def toString: String = f"Invoice($id, $total%.2f)"
  }

  // A companion object, holding an apply and a higher-order method.
  object Invoice {
    def empty(id: String): Invoice = new Invoice(id, Nil)

    def apply(id: String, lines: LineItem*): Invoice =
      new Invoice(id, lines.toList)

    def fold[A](invoice: Invoice)(zero: A)(step: (A, LineItem) => A): A =
      invoice.lines.foldLeft(zero)(step)
  }

  // An extension method and a given, the two Scala 3 shapes a reader expects.
  extension (invoice: Invoice)
    def isSettled: Boolean = invoice.compute() <= 0.0

  given Ordering[LineItem] with
    def compare(left: LineItem, right: LineItem): Int =
      left.amount.compare(right.amount)

  object Formatting {
    private val Symbol = "€"

    def money(value: Double): String = s"$Symbol${"%.2f".format(value)}"

    // An object nested inside an object.
    object Debug {
      def dump(invoice: Invoice): String = invoice.lines
        .map(line => s"${line.sku}=${money(line.amount)}")
        .mkString(", ")
    }
  }
}
