# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class BelongsToAssociation < SingleAssociation
        def type_key_name
          "#{as}_type"
        end

        def embeddable?
          false
        end

        def proxy_class
          @proxy_class ||= polymorphic? ? BelongsToPolymorphicProxy : BelongsToProxy
        end

        def setup(model)
          model.key foreign_key, ObjectId unless model.key?(foreign_key)
          model.key type_key_name, String unless model.key?(type_key_name) if polymorphic?
          super
          add_touch_callbacks if touch?
          add_counter_cache if counter_cache?
        end

        def autosave?
          options.fetch(:autosave, false)
        end

        def add_touch_callbacks
          name        = self.name
          method_name = "belongs_to_touch_after_save_or_destroy_for_#{name}"
          touch       = options.fetch(:touch)

          @model.send(:define_method, method_name) do
            record = send(name)

            unless record.nil?
              if touch == true
                record.touch
              else
                record.touch(touch)
              end
            end
          end

          @model.after_save(method_name)
          @model.after_touch(method_name)
          @model.after_destroy(method_name)
        end

        def add_counter_cache
          options = {}
          if @options[:counter_cache] && @options[:counter_cache] != true
            options[:field] = @options[:counter_cache]
          end

          @model.counter_cache name, options
        end
      end
    end
  end
end
