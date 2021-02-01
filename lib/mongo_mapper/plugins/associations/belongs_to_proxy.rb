# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class BelongsToProxy < Proxy
        def replace(doc)
          if doc
            doc.save if !doc.persisted?
            id = doc.id
          end

          reset
          proxy_owner[association.foreign_key] = id
          unless doc.nil?
            loaded
            @target = doc
          end
          @target
        end

        def build(attrs={}, &block)
          instantiate_target(:new, attrs, &block)
        end

        def create(attrs={}, &block)
          instantiate_target(:create, attrs, &block)
        end

        def create!(attrs={}, &block)
          instantiate_target(:create!, attrs, &block)
        end

        def save_to_collection(options={})
          @target.save(options) if @target
        end

      protected

        def find_target
          return nil if proxy_owner[association.foreign_key].nil?
          klass.find_by_id(proxy_owner[association.foreign_key])
        end

        def instantiate_target(instantiator, attrs={}, &block)
          @target = klass.send(instantiator, attrs, &block)
          proxy_owner[association.foreign_key] = @target.id
          loaded
          @target
        end

      private

        def stale_target?
          loaded? && @target && proxy_owner[association.foreign_key] != @target.id
        end
      end
    end
  end
end
