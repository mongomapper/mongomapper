# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class ManyAssociation < Base

        def class_name
          @class_name ||= options[:class_name] || name.to_s.singularize.camelize
        end

        def type_key_name
          "_type"
        end

        # hate this, need to revisit
        def proxy_class
          @proxy_class ||= if klass.embeddable?
            polymorphic? ? ManyEmbeddedPolymorphicProxy : ManyEmbeddedProxy
          else
            if polymorphic?
              ManyPolymorphicProxy
            elsif as?
              ManyDocumentsAsProxy
            elsif in_array?
              InArrayProxy
            else
              ManyDocumentsProxy
            end
          end
        end

        def setup(model)
          if options[:dependent] && !embeddable?
            model.after_destroy do |doc|
              case options[:dependent]
                when :destroy
                  doc.get_proxy(self).destroy_all
                when :delete_all
                  doc.get_proxy(self).delete_all
                when :nullify
                  doc.get_proxy(self).nullify
              end
            end
          end
        end

      end
    end
  end
end