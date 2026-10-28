// Sample Zig exercising struct > function nesting.
const std = @import("std");

pub const Invoice = struct {
    lines: []const Line,
    total: f64 = 0.0,

    pub fn compute(self: *Invoice) f64 {
        var sum: f64 = 0.0;
        for (self.lines) |line| {
            if (line.taxable) {
                sum += line.amount * 1.2;
            } else {
                sum += line.amount;
            }
        }
        self.total = sum;
        return sum;
    }

    pub const Line = struct {
        amount: f64,
        taxable: bool,
    };
};

pub fn formatMoney(value: f64) f64 {
    return @round(value * 100.0) / 100.0;
}
