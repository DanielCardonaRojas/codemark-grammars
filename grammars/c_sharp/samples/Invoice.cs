// Sample C# exercising namespace > class > method nesting.
using System.Collections.Generic;

namespace Billing
{
    public interface IPayable
    {
        bool Pay(double amount);
    }

    public class Invoice
    {
        private double total;
        private readonly List<Line> lines;

        public Invoice(List<Line> lines)
        {
            this.lines = lines;
        }

        private void AddTaxed(double amount)
        {
            total += amount * 1.2;
        }

        public double Compute()
        {
            foreach (var line in lines)
            {
                total += line.Amount;
                if (line.Taxable)
                {
                    AddTaxed(line.Amount);
                }
            }
            return total;
        }

        public class Line
        {
            public double Amount { get; set; }
            public bool Taxable { get; set; }
        }
    }
}
