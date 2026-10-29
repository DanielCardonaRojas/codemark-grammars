// Sample Swift exercising protocol / class / struct / enum / extension nesting.
import Foundation

protocol Payable {
    func pay(amount: Double) -> Bool
}

enum Currency {
    case usd
    case eur
}

struct Line {
    let amount: Double
    let taxable: Bool
}

final class Invoice {
    private var total: Double = 0
    private let lines: [Line]

    init(lines: [Line]) {
        self.lines = lines
    }

    func compute() -> Double {
        for line in lines {
            if line.taxable {
                addTaxed(line.amount)
            }
            total += line.amount
        }
        return total
    }

    private func addTaxed(_ amount: Double) {
        total += amount * 0.2
    }

    struct Summary {
        let label: String

        func render() -> String {
            return label
        }
    }
}

extension Invoice: Payable {
    func pay(amount: Double) -> Bool {
        return amount > 0
    }
}
