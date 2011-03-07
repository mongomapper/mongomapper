# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class OneAssociation < BelongsToAssociation
        def embeddable?
          klass.embeddable?
        end

        def proxy_class
          @proxy_class ||= klass.embeddable? ? OneEmbeddedProxy : OneProxy
        end
      end
    end
  end
end