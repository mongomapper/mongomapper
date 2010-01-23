require 'active_support/json'

module MongoMapper
  module Plugins
    module Serialization
      def self.configure(model)
        model.class_eval { include Json }
      end
      
      class Serializer
        attr_reader :options

        def initialize(record, options={})
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
      
      module Json
        def self.included(base)
          base.cattr_accessor :include_root_in_json, :instance_writer => false
          base.extend ClassMethods
        end

        module ClassMethods
          def json_class_name
            @json_class_name ||= name.demodulize.underscore.inspect
          end
        end

        def to_json(options={})
          apply_to_json_defaults(options)

          if include_root_in_json
            "{#{self.class.json_class_name}: #{JsonSerializer.new(self, options).to_s}}"
          else
            JsonSerializer.new(self, options).to_s
          end
        end

        def from_json(json)
          self.attributes = ActiveSupport::JSON.decode(json)
          self
        end

        class JsonSerializer < Serializer
          def serialize
            serializable_record.to_json
          end
        end

        private
          def apply_to_json_defaults(options)
            unless options[:only]
              methods = [options.delete(:methods)].flatten.compact
              methods << :id
              options[:methods] = methods.uniq
            end

            except = [options.delete(:except)].flatten.compact
            except << :_id
            options[:except] = except
          end
      end
    end
  end
end