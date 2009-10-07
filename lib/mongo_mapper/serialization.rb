require 'active_support/json'

module MongoMapper #:nodoc:
  module Serialization
    class Serializer #:nodoc:
      attr_reader :options

      def initialize(record, options = {})
        @record, @options = record, options.dup
      end

      def serializable_key_names
        key_names = @record.attributes.keys

        if options[:only]
          options.delete(:except)
          key_names = key_names & Array(options[:only]).collect { |n| n.to_s }
        else
          options[:except] = Array(options[:except])
          key_names = key_names - options[:except].collect { |n| n.to_s }
        end

        key_names
      end

      def serializable_method_names
        Array(options[:methods]).inject([]) do |method_attributes, name|
          method_attributes << name if @record.respond_to?(name.to_s)
          method_attributes
        end
      end

      def serializable_names
        serializable_key_names + serializable_method_names
      end

      def serializable_record
        returning(serializable_record = {}) do
          serializable_names.each { |name| serializable_record[name] = @record.send(name) }
        end
      end

      def serialize
        # overwrite to implement
      end

      def to_s(&block)
        serialize(&block)
      end
    end
  end
end

dir = Pathname(__FILE__).dirname.expand_path + 'serializers'
require dir + 'json_serializer'
