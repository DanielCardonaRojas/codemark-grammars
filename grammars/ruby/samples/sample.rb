# Sample Ruby exercising the constructs the profile claims to understand.
module Billing
  class Invoice
    attr_reader :total

    def initialize(lines)
      @lines = lines
      @total = 0
    end

    def compute
      @lines.each do |line|
        if line.taxable?
          @total += line.amount * 1.2
        else
          @total += line.amount
        end
      end
      @total
    end

    def self.empty
      new([])
    end

    class LineItem
      def amount
        @amount
      end
    end
  end
end
