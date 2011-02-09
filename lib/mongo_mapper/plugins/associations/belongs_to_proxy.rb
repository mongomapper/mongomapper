# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class BelongsToProxy < Proxy
        def replace(doc)
          if doc
            doc.save if doc.new?
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

        protected
          def find_target
            return nil if proxy_owner[association.foreign_key].nil?
            klass.find_by_id(proxy_owner[association.foreign_key])
          end
      end
    end
  end
end
