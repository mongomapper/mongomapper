# encoding: UTF-8
module MongoMapper
  module Plugins
    module Rails
      extend ActiveSupport::Concern

      module InstanceMethods
        def to_param
          id.to_s if persisted?
        end

        def to_model
          self
        end

        def to_key
          [id] if persisted?
        end

        def new_record?
          new?
        end

        def read_attribute(name)
          self[name]
        end

        def read_attribute_before_type_cast(name)
          read_key_before_type_cast(name)
        end

        def write_attribute(name, value)
          self[name] = value
        end
      end

      module ClassMethods
        def has_one(*args)
          one(*args)
        end

        def has_many(*args, &extension)
          many(*args, &extension)
        end

        def column_names
          keys.keys
        end

        def human_name
          self.name.demodulize.titleize
        end
      end
    end
  end
end