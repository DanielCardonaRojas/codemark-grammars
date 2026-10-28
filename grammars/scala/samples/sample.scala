// Sample Scala exercising package > object/class > def nesting.
package app.billing

case class Line(amount: Double, taxable: Boolean)

class Invoice(val lines: List[Line]) {
  private var total: Double = 0.0
  private val taxRate: Double = 1.2

  private def applyTax(amount: Double): Double = total + amount * taxRate

  def compute(): Double = {
    for (line <- lines) {
      if (line.taxable) {
        total = applyTax(line.amount)
      } else {
        total += line.amount
      }
    }
    total
  }

  class Summary(val label: String) {
    def render(): String = s"$label: $total"
  }
}

object Invoice {
  def empty: Invoice = new Invoice(Nil)
}

trait Payable {
  def pay(amount: Double): Boolean
}
