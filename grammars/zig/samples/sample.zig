// Idiomatic Zig exercising the constructs this profile claims to understand.
//
// Authored for this repo. tree-sitter-zig ships NO test/corpus — ADR-001
// surveyed every grammar in the registry and this is the one exception — so
// there is no breadth source to fall back on and this hand-written sample is
// all the coverage there is. That makes it the sample most worth being
// thorough in.
//
// The structural fact that shapes everything here: a Zig struct is an anonymous
// value bound by the enclosing `variable_declaration`, so `struct_declaration`
// has no name field of its own and can never be a container. Breadcrumbs
// therefore name the *function*, never the struct — which is why this sample
// nests a declaration inside a function rather than relying on type nesting.

const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

const DEFAULT_TAX_RATE: f64 = 1.2;
const MAX_LINES: usize = 64;

pub const InvoiceState = enum {
    draft,
    issued,
    paid,

    // A method on an enum. The enum is bound by a variable_declaration, so a
    // breadcrumb for anything in here names this function and not the enum.
    pub fn isSettled(self: InvoiceState) bool {
        return self == .paid;
    }
};

pub const InvoiceError = error{
    NoLines,
    TooManyLines,
};

pub const LineItem = struct {
    sku: []const u8,
    amount: f64,
    taxable: bool,

    pub fn isVoid(self: LineItem) bool {
        return self.amount == 0.0;
    }

    pub fn taxed(self: LineItem, rate: f64) f64 {
        return self.amount * rate;
    }
};

pub const Invoice = struct {
    lines: []const LineItem,
    state: InvoiceState = .draft,
    total: f64 = 0.0,

    const Self = @This();

    pub fn init(lines: []const LineItem) InvoiceError!Self {
        if (lines.len == 0) {
            return InvoiceError.NoLines;
        }

        if (lines.len > MAX_LINES) {
            return InvoiceError.TooManyLines;
        }

        return Self{ .lines = lines };
    }

    // A function whose body holds a for loop containing a switch containing a
    // conditional — the deepest chain this language's breadcrumbs describe.
    pub fn compute(self: *Self) f64 {
        var sum: f64 = 0.0;

        for (self.lines) |line| {
            switch (line.taxable) {
                true => {
                    const taxed = line.taxed(DEFAULT_TAX_RATE);
                    sum += taxed;
                },
                false => {
                    if (line.isVoid()) {
                        continue;
                    }
                    sum += line.amount;
                },
            }
        }

        self.total = sum;
        return sum;
    }

    // An error union return with `try`, plus a `defer` — the two idioms that
    // define Zig control flow and that a reader expects to see.
    pub fn render(self: Self, allocator: Allocator) ![]u8 {
        var list = std.ArrayList(u8).init(allocator);
        defer list.deinit();

        try list.writer().print("invoice: {d:.2}", .{self.total});

        // A struct declared inside a function body, holding a function. This
        // is the only shape that gives Zig a two-level breadcrumb, since the
        // struct itself cannot be a container.
        const Helper = struct {
            fn label(state: InvoiceState) []const u8 {
                return switch (state) {
                    .draft => "draft",
                    .issued => "issued",
                    .paid => "paid",
                };
            }
        };

        try list.writer().print(" [{s}]", .{Helper.label(self.state)});
        return list.toOwnedSlice();
    }

    pub fn pay(self: *Self, amount: f64) InvoiceError!bool {
        const remaining = self.compute() - amount;

        if (remaining <= 0.0) {
            self.state = .paid;
            return true;
        }

        self.state = .issued;
        return false;
    }

    // A while loop with a continue expression, the loop spelling the old
    // sample never reached.
    pub fn countTaxable(self: Self) usize {
        var index: usize = 0;
        var found: usize = 0;

        while (index < self.lines.len) : (index += 1) {
            if (self.lines[index].taxable) {
                found += 1;
            }
        }

        return found;
    }
};

// A generic function using `comptime`, which is Zig's defining feature.
pub fn sumBy(comptime T: type, items: []const T, pick: fn (T) f64) f64 {
    var total: f64 = 0.0;

    for (items) |item| {
        total += pick(item);
    }

    return total;
}

pub fn formatMoney(value: f64) f64 {
    return @round(value * 100.0) / 100.0;
}

test "compute applies tax to taxable lines" {
    const lines = [_]LineItem{
        .{ .sku = "a", .amount = 100.0, .taxable = true },
        .{ .sku = "b", .amount = 50.0, .taxable = false },
    };

    var invoice = try Invoice.init(&lines);
    const total = invoice.compute();

    try testing.expectApproxEqAbs(@as(f64, 170.0), total, 0.001);
}
