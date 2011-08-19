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
                  nullify_scope(target)
                  target.save
              end
            end
          end
          
          unless doc.nil?
            proxy_owner.save unless proxy_owner.persisted?
            doc = klass.new(doc) unless doc.is_a?(klass)
            apply_scope(doc)
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
          nullify_scope(target)
          target.save
          reset
        end

        protected
          def find_target
            target_class.first(association.query_options.merge(criteria))
          end

          def instantiate_target(instantiator, attrs={})
            @target = target_class.send(instantiator, attrs.update(criteria))
            loaded
            @target
          end

          def target_class
            @target_class ||= options[:class] || (options[:class_name] || association.name.to_s.camelize).constantize
          end

          def foreign_key
            options[:foreign_key] || proxy_owner.class.name.foreign_key
          end

          def criteria
            {self.foreign_key => proxy_owner.id}
          end

          def nullify_scope(doc)
            criteria.each { |key, value| doc[key] = nil }
            doc
          end

          def apply_scope(doc)
            criteria.each { |key, value| doc[key] = value }
            doc
          end
      end
    end
  end
end
