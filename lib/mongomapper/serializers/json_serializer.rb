module MongoMapper #:nodoc:
  module Serialization
    def self.included(base)
      base.cattr_accessor :include_root_in_json, :instance_writer => false
      base.extend ClassMethods
    end

    # Returns a JSON string representing the model. Some configuration is
    # available through +options+.
    #
    # The option <tt>include_root_in_json</tt> controls the top-level behavior of
    # to_json. When it is <tt>true</tt>, to_json will emit a single root node named
    # after the object's type. For example:
    #
    #   konata = User.find(1)
    #   User.include_root_in_json = true
    #   konata.to_json
    #   # => { "user": {"id": 1, "name": "Konata Izumi", "age": 16,
    #                   "created_at": "2006/08/01", "awesome": true} }
    #
    #   User.include_root_in_json = false
    #   konata.to_json
    #   # => {"id": 1, "name": "Konata Izumi", "age": 16,
    #         "created_at": "2006/08/01", "awesome": true}
    #
    # The remainder of the examples in this section assume include_root_in_json is set to
    # <tt>false</tt>.
    #
    # Without any +options+, the returned JSON string will include all
    # the model's attributes. For example:
    #
    #   konata = User.find(1)
    #   konata.to_json
    #   # => {"id": 1, "name": "Konata Izumi", "age": 16,
    #         "created_at": "2006/08/01", "awesome": true}
    #
    # The <tt>:only</tt> and <tt>:except</tt> options can be used to limit the attributes
    # included, and work similar to the +attributes+ method. For example:
    #
    #   konata.to_json(:only => [ :id, :name ])
    #   # => {"id": 1, "name": "Konata Izumi"}
    #
    #   konata.to_json(:except => [ :id, :created_at, :age ])
    #   # => {"name": "Konata Izumi", "awesome": true}
    #
    # To include any methods on the model, use <tt>:methods</tt>.
    #
    #   konata.to_json(:methods => :permalink)
    #   # => {"id": 1, "name": "Konata Izumi", "age": 16,
    #         "created_at": "2006/08/01", "awesome": true,
    #         "permalink": "1-konata-izumi"}
    def to_json(options = {})
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

    class JsonSerializer < MongoMapper::Serialization::Serializer #:nodoc:
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
