/**
 * Idiomatic Java exercising the constructs this profile claims to understand.
 *
 * Authored for this repo. Construct coverage was cross-checked against
 * tree-sitter-java's own test/corpus topics (declarations, statements,
 * expressions) — read as a checklist, not copied.
 *
 * Every container kind below actually contains something: a class holds
 * methods and a nested class, an interface holds a default method, an enum
 * holds a constant body, a method holds statements and a lambda. An empty
 * declaration would teach the generator nothing about containment, which is
 * the whole point of the snapshot check.
 */
package com.example.billing;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;

/** An interface whose body holds a signature and a defaulted method. */
interface Payable {
    double total();

    default boolean isFree() {
        return total() == 0.0;
    }
}

/** An enum whose constants carry a body — `enum_constant` as a container. */
enum State {
    DRAFT("open"),
    PAID("settled") {
        @Override
        String describe() {
            return "fully " + label();
        }
    };

    private final String label;

    State(String label) {
        this.label = label;
    }

    String label() {
        return label;
    }

    String describe() {
        return label;
    }
}

/** A record — a distinct node kind from `class_declaration`. */
record LineItem(double amount, boolean taxable) implements Payable {
    static final double TAX_RATE = 1.2;

    @Override
    public double total() {
        if (taxable) {
            return amount * TAX_RATE;
        }

        return amount;
    }
}

/** The aggregate the rest of this sample nests inside. */
public class Invoice implements Payable {
    /** A constant field — `field_declaration`. */
    public static final String VERSION = "1.0.0";

    private final List<LineItem> lines;
    private State state;

    /** A constructor nesting statements — `constructor_declaration`. */
    public Invoice(List<LineItem> lines) {
        this.lines = new ArrayList<>(lines);
        this.state = State.DRAFT;
    }

    /** A static factory holding a loop. */
    public static Invoice of(double... amounts) {
        List<LineItem> items = new ArrayList<>();

        for (double amount : amounts) {
            items.add(new LineItem(amount, amount > 100.0));
        }

        return new Invoice(items);
    }

    /**
     * A method whose body holds a conditional and a loop — the deepest
     * control-flow chain among these methods.
     */
    @Override
    public double total() {
        if (state == State.PAID) {
            return 0.0;
        }

        double sum = 0.0;

        for (LineItem line : lines) {
            if (line.amount() == 0.0) {
                continue;
            }

            sum += line.total();
        }

        return sum;
    }

    /** A method holding a lambda — `lambda_expression` as a bookmarkable body. */
    public double discounted(double pct) {
        Function<Double, Double> apply = amount -> {
            // A lambda nested in a method: the deepest named chain here.
            return amount * (1 - pct);
        };

        double sum = 0.0;

        for (LineItem line : lines) {
            sum += apply.apply(line.amount());
        }

        return sum;
    }

    /** A method using a switch — distinct from an if-chain in the grammar. */
    public String describe() {
        switch (state) {
            case PAID:
                return "settled";
            case DRAFT:
                return "open";
            default:
                return "unknown";
        }
    }

    public void settle() {
        try {
            this.state = State.PAID;
        } catch (RuntimeException e) {
            this.state = State.DRAFT;
        }
    }

    /** A class nested inside a class — proves class-in-class containment. */
    static class Draft {
        private final Invoice owner;

        Draft(Invoice owner) {
            this.owner = owner;
        }

        /** A method in a nested class: three container levels deep. */
        Invoice promote() {
            owner.state = State.DRAFT;

            return owner;
        }

        /** A method holding an anonymous class — `object_creation_expression`
         *  with a body, whose method sits deeper still. */
        Payable asPayable() {
            return new Payable() {
                @Override
                public double total() {
                    return owner.total();
                }
            };
        }
    }
}
