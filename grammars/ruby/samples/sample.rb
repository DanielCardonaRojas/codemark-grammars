# Idiomatic Ruby exercising the constructs this profile claims to understand.
#
# Authored for this repo. Construct coverage was cross-checked against
# tree-sitter-ruby's own test/corpus topics (declarations, control-flow,
# statements, patterns) — read as a checklist, not copied.
#
# Every container kind below actually contains something: a module holds a
# class, a class holds methods and a nested class, methods hold statements.
# An empty declaration would teach the generator nothing about containment.

require "forwardable"

module Billing
  VERSION = "1.0.0"

  # A module nested in a module — the outermost breadcrumb level.
  module Formatting
    def self.money(value)
      format("%.2f", value)
    end
  end

  class InvoiceError < StandardError
    def initialize(invoice_id)
      @invoice_id = invoice_id
      super("invoice #{invoice_id} is not payable")
    end

    attr_reader :invoice_id
  end

  class Invoice
    extend Forwardable
    include Comparable

    attr_reader :lines, :state

    def_delegators :@lines, :size, :empty?

    def initialize(lines, state: :draft)
      @lines = lines
      @state = state
      @total = 0.0
    end

    # A method whose body holds a block, a conditional and a guard clause.
    def compute
      raise InvoiceError, object_id unless payable?

      @lines.each do |line|
        next if line.void?

        @total += if line.taxable?
                    taxed(line.amount)
                  else
                    line.amount
                  end
      end

      @total
    end

    def <=>(other)
      total <=> other.total
    end

    def to_s
      "#<Invoice #{Formatting.money(@total)}>"
    end

    def self.empty
      new([])
    end

    class << self
      def from_hash(attrs)
        new(attrs.fetch(:lines, []))
      end
    end

    # A class nested inside a class — proves type-in-type containment.
    class LineItem
      attr_accessor :amount

      def initialize(amount, taxable: false)
        @amount = amount
        @taxable = taxable
      end

      def taxable?
        @taxable
      end

      def void?
        @amount.zero?
      end
    end

    private

    def taxed(amount)
      amount * 1.2
    end

    def payable?
      @state != :paid
    end
  end
end
