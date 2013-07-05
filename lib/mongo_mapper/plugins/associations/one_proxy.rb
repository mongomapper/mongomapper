# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class OneProxy < Proxy
        def build(attrs={}, &block)
          instantiate_target(:new, attrs, &block)
        end

        def create(attrs={}, &block)
          instantiate_target(:create, attrs, &block)
        end

        def create!(attrs={}, &block)
          instantiate_target(:create!, attrs, &block)
        end

        def replace(doc)
          load_target

          if !target.nil? && target != doc && target.persisted?
            association.dirty[:nullify] << target
          end

          unless doc.nil?
            association.dirty[:self] = true
            doc = klass.new(doc) unless doc.is_a?(klass)
            apply_scope(doc)
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

          def instantiate_target(instantiator, attrs={}, &block)
            @target = target_class.send(instantiator, attrs.update(criteria), &block)
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
