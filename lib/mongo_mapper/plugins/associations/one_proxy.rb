module MongoMapper
  module Plugins
    module Associations
      class OneProxy < Proxy
        undef_method :object_id
        
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
            if options[:dependent] && !target.new?
              case options[:dependent]
                when :delete
                  target.delete
                when :destroy
                  target.destroy
                when :nullify
                  target[foreign_key] = nil
                  target.save
              end
            end
          end

          reset

          unless doc.nil?
            owner.save if owner.new?
            doc[foreign_key] = owner.id
            doc.save if doc.new?
            loaded
            @target = doc
          end
        end

        protected
          def find_target
            target_class.first(association.query_options.merge(foreign_key => owner.id))
          end

          def instantiate_target(instantiator, attrs={})
            @target = target_class.send(instantiator, attrs.update(foreign_key => owner.id))
            loaded
            @target
          end

          def target_class
            @target_class ||= options[:class] || (options[:class_name] || association.name.to_s.camelize).constantize
          end

          def foreign_key
            options[:foreign_key] || owner.class.name.foreign_key
          end
      end
    end
  end
end
