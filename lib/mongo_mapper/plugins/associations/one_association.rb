# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class OneAssociation < Base

        def proxy_class
          @proxy_class ||= klass.embeddable? ? OneEmbeddedProxy : OneProxy
        end

      end
    end
  end
end