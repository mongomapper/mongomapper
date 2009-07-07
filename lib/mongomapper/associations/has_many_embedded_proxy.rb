module MongoMapper
  module Associations
    class HasManyEmbeddedProxy < Proxy
      protected
      def find_target
        (@association.value || []).map do |e|
          @association.klass.new(e)
        end
      end
    end
  end
end
