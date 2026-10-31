// Idiomatic Swift exercising the constructs this profile claims to understand.
//
// Authored for this repo. Construct coverage was cross-checked against
// tree-sitter-swift's own test/corpus topics (declarations, expressions,
// statements, patterns) — read as a checklist, not copied.
//
// Swift has no namespace construct, so the outermost breadcrumb level is a
// type. What this sample must prove instead is that every *kind* of type
// declaration works as a container — class, struct, enum, protocol, extension
// — and that initialisers, subscripts and computed properties, which have no
// `name` field in the usual sense, behave as the profile claims.

import Foundation

protocol Payable {
    var currency: Currency { get }

    func pay(amount: Decimal) -> Bool

    // A protocol method with a default implementation lives in an extension,
    // not the protocol body — see `extension Payable` below.
    func describe() -> String
}

enum Currency: String, CaseIterable {
    case usd = "USD"
    case eur = "EUR"

    // A computed property on an enum, so the enum contains a declaration and
    // not only cases.
    var symbol: String {
        switch self {
        case .usd:
            return "$"
        case .eur:
            return "€"
        }
    }
}

enum InvoiceError: Error {
    case noLines
    case tooManyLines(limit: Int)
}

struct LineItem: Identifiable, Comparable {
    let id: UUID
    let sku: String
    let amount: Decimal
    let taxable: Bool

    var isVoid: Bool {
        amount == .zero
    }

    init(sku: String, amount: Decimal, taxable: Bool = false) {
        self.id = UUID()
        self.sku = sku
        self.amount = amount
        self.taxable = taxable
    }

    func taxed(rate: Decimal) -> Decimal {
        amount * (1 + rate)
    }

    static func < (lhs: LineItem, rhs: LineItem) -> Bool {
        lhs.amount < rhs.amount
    }
}

final class Invoice {
    private static let taxRate: Decimal = 0.2

    private let lines: [LineItem]
    private(set) var total: Decimal = .zero
    private(set) var state: State = .draft

    // A nested enum inside a class — proves type-in-type containment for a
    // kind other than struct.
    enum State {
        case draft
        case issued
        case paid
    }

    // An initialiser that can fail, holding real statements.
    init(lines: [LineItem]) throws {
        guard !lines.isEmpty else {
            throw InvoiceError.noLines
        }

        self.lines = lines
    }

    deinit {
        total = .zero
    }

    // A subscript: a declaration with no identifier name at all.
    subscript(index: Int) -> LineItem {
        lines[index]
    }

    // A computed property with an explicit getter body, so the accessor holds
    // a statement rather than being a one-line expression.
    var summary: String {
        get {
            let suffix = lines.count == 1 ? "line" : "lines"
            return "\(lines.count) \(suffix)"
        }
    }

    // A method whose body holds a for loop containing a switch containing a
    // conditional — the deepest chain in this file.
    func compute() -> Decimal {
        total = .zero

        for line in lines {
            switch (line.taxable, line.isVoid) {
            case (_, true):
                continue
            case (true, false):
                let taxed = line.taxed(rate: Self.taxRate)
                total += taxed
            case (false, false):
                total += line.amount
            }
        }

        // A function nested inside a function body.
        func rounded(_ value: Decimal) -> Decimal {
            var result = Decimal()
            var input = value
            NSDecimalRound(&result, &input, 2, .plain)
            return result
        }

        total = rounded(total)
        return total
    }

    // async/throws plus a trailing closure, the two idioms a Swift reader
    // expects to see.
    func settle(using gateway: (Decimal) async throws -> Bool) async throws -> State {
        let billable = lines
            .filter { !$0.isVoid }
            .sorted(by: >)

        guard !billable.isEmpty else {
            throw InvoiceError.tooManyLines(limit: billable.count)
        }

        // `try await` is bound to a local rather than written inline in the
        // condition: tree-sitter-swift 0.7.3 cannot parse
        // `if try await gateway(...)`, which is valid Swift. A sample must
        // parse cleanly or the generated profile is derived from a broken tree.
        let accepted = try await gateway(compute())

        if accepted {
            state = .paid
        } else {
            state = .issued
        }

        return state
    }

    // A struct nested inside a class, holding its own method.
    struct Receipt {
        let label: String
        let issuedAt: Date

        func render() -> String {
            let formatter = ISO8601DateFormatter()
            return "\(label) @ \(formatter.string(from: issuedAt))"
        }
    }
}

// An extension conforming a type to a protocol — the ordinary Swift way to
// organise code, and a container kind of its own.
extension Invoice: Payable {
    var currency: Currency {
        .eur
    }

    func pay(amount: Decimal) -> Bool {
        total -= amount
        return total <= .zero
    }
}

// A protocol extension supplying a default implementation.
extension Payable {
    func describe() -> String {
        "payable in \(currency.symbol)"
    }
}

// An extension on a generic standard-library type with a constraint.
extension Array where Element == LineItem {
    var taxableTotal: Decimal {
        reduce(into: Decimal.zero) { running, line in
            if line.taxable {
                running += line.amount
            }
        }
    }
}
