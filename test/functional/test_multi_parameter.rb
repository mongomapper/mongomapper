require 'test_helper'

class MultiParameterTest < Test::Unit::TestCase
  context 'A document with a Date attribute' do
    setup do
      @doc_class = Doc do
        key :some_date, Date
      end

      @doc = @doc_class.create
    end

    should 'be able to receive a date as multiple parameters through mass assignment' do
      @doc_class.update_attributes! "some_date(i1)" => "2000"
      assert_not_nil @doc.some_date
    end
  end
end
