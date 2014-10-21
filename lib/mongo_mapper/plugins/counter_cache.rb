module MongoMapper
  module Plugins
    # Counter Caching for MongoMapper::Document
    #
    # Examples:
    #
    #   class Post
    #     belongs_to :user
    #     counter_cache :user
    #   end
    #
    #   or:
    #
    #   class Post
    #     belongs_to :user
    #     counter_cache :user, :custom_posts_count
    #   end
    #
    # Field names follow rails conventions, so counter_cache :user will increment the Integer field `posts_count' on User
    #
    # Alternatively, you can also use the more common ActiveRecord syntax:
    #
    #   class Post
    #     belongs_to :user, :counter_cache => true
    #   end
    #
    # Or with an alternative field name:
    #
    #   class Post
    #     belongs_to :user, :counter_cache => :custom_posts_count
    #   end
    #
    module CounterCache
      class InvalidCounterCacheError < StandardError; end

      extend ActiveSupport::Concern

      module ClassMethods
        def counter_cache(association_name, options = {})
          options.symbolize_keys!

          field = options[:field] ?
            options[:field] :
            "#{self.collection_name.gsub(/.*\./, '')}_count"

          association = associations[association_name]

          if !association
            raise InvalidCounterCacheError, "You must define an association with name `#{association_name}' on model #{self}"
          end

          association_class = association.klass
          key_names = association_class.keys.keys

          if !key_names.include?(field.to_s)
            raise InvalidCounterCacheError, "Missing `key #{field.to_sym.inspect}, Integer, :default => 0' on model #{association_class}"
          end

          after_create do
            if obj = self.send(association_name)
              obj.increment(field => 1)
              obj.write_attribute(field, obj.read_attribute(field) + 1)
            end
            true
          end

          after_destroy do
            if obj = self.send(association_name)
              obj.decrement(field => 1)
              obj.write_attribute(field, obj.read_attribute(field) - 1)
            end
            true
          end
        end
      end
    end
  end
end
