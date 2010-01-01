module MongoMapper
  module Serialization
    def self.included(base)
      base.cattr_accessor :include_root_in_json, :instance_writer => false
      base.extend ClassMethods
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

    class JsonSerializer < MongoMapper::Serialization::Serializer
      def serialize
        serializable_record.to_json
      end
    end

    module ClassMethods
      def json_class_name
        @json_class_name ||= name.demodulize.underscore.inspect
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
