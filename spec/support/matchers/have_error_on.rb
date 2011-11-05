module RSpec
  module Matchers
    class HaveErrorOn
      def initialize(attribute, expected_message = nil, &block)
        @attribute = attribute
        @expected_message = expected_message
        @block = block
      end

      def matches?(model)
        model.valid?
        @actual_errors = model.errors[@attribute]

        if @expected_message
          @actual_errors.include?(@expected_message)
        else
          !@actual_errors.blank?
        end
      end

      def failure_message_for_should
        "expected an error on #{expected_error}#{given_error}"
      end

      def failure_message_for_should_not
        "expected no error on #{expected_error}#{given_error}"
      end

      def description
        "have an error on #{expected_error}"
      end

    private

      def expected_error
        @expected_message ? "#{@attribute} with #{@expected_message.inspect}" : @attribute
      end

      def given_error
        ", but got #{@actual_errors.inspect}" unless @actual_errors.blank?
      end
    end

    def have_error_on(attribute, message = nil, &block)
      Matchers::HaveErrorOn.new(attribute, message, &block)
    end
  end
end
