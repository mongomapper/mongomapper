# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class OneProxy < Proxy
        def build(attrs={})
          instantiate_target(:new, attrs)
        end

        def create(attrs={})
          instantiate_target(:create, attrs)
        end

        def create!(attrs={})
          instantiate_target(:create!, attrs)
        end

        def replace(doc)
          load_target

          if !target.nil? && target != doc
            if target.persisted?
              case options[:dependent]
                when :delete  then target.delete
                when :destroy then target.destroy
                else
                  target[foreign_key] = nil
                  target.save
              end
            end
          end
          
          unless doc.nil?
            proxy_owner.save unless proxy_owner.persisted?
            doc = klass.new(doc) unless doc.is_a?(klass)
            doc[foreign_key] = proxy_owner.id
            doc.save unless doc.persisted?
          end

          loaded
          @target = doc
        end
        
        def destroy
          target.destroy
          reset
        end
        
        def delete
          target.delete
          reset
        end
        
        def nullify
          target.update_attributes(foreign_key => nil)
          reset
        end

        protected
          def find_target
            target_class.first(association.query_options.merge(foreign_key => proxy_owner.id))
          end

          def instantiate_target(instantiator, attrs={})
            @target = target_class.send(instantiator, attrs.update(foreign_key => proxy_owner.id))
            loaded
            @target
          end

          def target_class
            @target_class ||= options[:class] || (options[:class_name] || association.name.to_s.camelize).constantize
          end

          def foreign_key
            options[:foreign_key] || proxy_owner.class.name.foreign_key
          end
      end
    end
  end
end
