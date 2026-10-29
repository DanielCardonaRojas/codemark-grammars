// Idiomatic C# exercising the constructs this profile claims to understand.
//
// Authored for this repo. Construct coverage was cross-checked against
// tree-sitter-c-sharp's own test/corpus topics (declarations, expressions,
// statements, patterns) — read as a checklist, not copied.
//
// ADR-001 measured this language specifically: the grammar's corpus is
// breadth-first and structurally flat (98 of 154 C# blocks sit at brace depth
// <= 1), so it finds rare kinds but misses ordinary nesting — a constructor
// with a body appears in real code and not in a parser test. This sample is the
// other half of that trade: every container kind actually contains something,
// and the chain reaches four levels (namespace > class > method > statement).

using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Billing.Invoicing
{
    public interface IPayable
    {
        bool Pay(decimal amount);

        // A default interface member: a method with a body inside an interface.
        string Describe() => $"payable in {Currency}";

        string Currency { get; }
    }

    public enum InvoiceState
    {
        Draft,
        Issued,
        Paid,
    }

    public delegate void InvoiceSettled(Guid invoiceId, decimal amount);

    public record LineItem(string Sku, decimal Amount, bool Taxable)
    {
        public decimal Taxed(decimal rate) => Amount * (1m + rate);
    }

    public readonly struct Money
    {
        public Money(decimal amount, string currency)
        {
            Amount = amount;
            Currency = currency;
        }

        public decimal Amount { get; }

        public string Currency { get; }

        public override string ToString() => $"{Amount:0.00} {Currency}";
    }

    public class InvoiceException : Exception
    {
        public InvoiceException(Guid invoiceId, string message)
            : base(message)
        {
            InvoiceId = invoiceId;
        }

        public Guid InvoiceId { get; }
    }

    public class Invoice : IPayable
    {
        private const decimal DefaultTaxRate = 0.2m;

        private readonly List<LineItem> lines;
        private decimal total;

        // A constructor with a real body — the kind the grammar's own corpus
        // never nests, per ADR-001.
        public Invoice(Guid id, List<LineItem> lines)
        {
            if (lines is null)
            {
                throw new ArgumentNullException(nameof(lines));
            }

            Id = id;
            this.lines = lines;
            State = InvoiceState.Draft;
        }

        public event InvoiceSettled Settled;

        public Guid Id { get; }

        public InvoiceState State { get; private set; }

        public string Currency => "EUR";

        // A property with an explicit accessor body, so `accessor_declaration`
        // holds a statement rather than being auto-implemented.
        public decimal Total
        {
            get => total;
            private set
            {
                total = value < 0m ? 0m : value;
            }
        }

        // An indexer: a declaration named by its parameter rather than an
        // identifier. Only the corpus finds this one.
        public LineItem this[int index] => lines[index];

        // A method whose body holds a foreach containing a switch containing a
        // pattern: namespace > class > method > foreach > switch is the deepest
        // chain in this file.
        public decimal Compute()
        {
            Total = 0m;

            foreach (var line in lines)
            {
                // Each arm is given a different shape on purpose: identical
                // sibling statements make the generated structural query
                // ambiguous and codemark refuses the bookmark. A
                // sample-authoring constraint, not a profile defect.
                switch (line)
                {
                    case { Taxable: true } taxable:
                        var taxed = taxable.Taxed(DefaultTaxRate);
                        Total += taxed;
                        break;

                    case { Amount: 0m }:
                        continue;

                    default:
                        Total += line.Amount;
                        break;
                }
            }

            // A local function: a declaration nested inside a method body.
            decimal Rounded(decimal value)
            {
                return Math.Round(value, 2, MidpointRounding.AwayFromZero);
            }

            Total = Rounded(Total);
            return Total;
        }

        // async/await plus LINQ, the two idioms a C# reader expects to see.
        public async Task<Money> SettleAsync(Func<decimal, Task<bool>> gateway)
        {
            var billable = lines
                .Where(line => line.Amount > 0m)
                .OrderByDescending(line => line.Amount)
                .ToList();

            if (billable.Count == 0)
            {
                throw new InvoiceException(Id, "nothing to settle");
            }

            var accepted = await gateway(Compute()).ConfigureAwait(false);

            if (accepted)
            {
                State = InvoiceState.Paid;
                Settled?.Invoke(Id, Total);
            }

            return new Money(Total, Currency);
        }

        public bool Pay(decimal amount)
        {
            try
            {
                Total -= amount;
                return Total <= 0m;
            }
            catch (InvalidOperationException ex) when (ex.InnerException is not null)
            {
                throw new InvoiceException(Id, ex.Message);
            }
            finally
            {
                State = Total <= 0m ? InvoiceState.Paid : InvoiceState.Issued;
            }
        }

        public static implicit operator decimal(Invoice invoice) => invoice.Total;

        public static Invoice operator +(Invoice invoice, LineItem line)
        {
            invoice.lines.Add(line);
            return invoice;
        }

        // A class nested inside a class, holding its own method — proves
        // type-in-type containment.
        public sealed class Summary
        {
            public Summary(Invoice invoice)
            {
                Label = $"{invoice.Id:N}";
                Count = invoice.lines.Count;
            }

            public string Label { get; }

            public int Count { get; }

            public string Render()
            {
                var suffix = Count == 1 ? "line" : "lines";
                return $"{Label}: {Count} {suffix}";
            }
        }
    }

    // A generic class with a real constraint, plus a static dictionary — the
    // ordinary generic shape rather than the corpus's `class F<in T1, out T2>`.
    public static class InvoiceBook<TInvoice>
        where TInvoice : IPayable
    {
        private static readonly Dictionary<string, TInvoice> Entries = new();

        public static void Register(string key, TInvoice invoice)
        {
            Entries[key] = invoice;
        }

        public static bool TryFind(string key, out TInvoice invoice)
        {
            return Entries.TryGetValue(key, out invoice);
        }
    }
}
