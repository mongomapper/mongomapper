# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class OneAsProxy < OneProxy
        protected
          def criteria
            {type_key_name => proxy_owner.class.name, id_key_name => proxy_owner.id}
          end
        
        private
          def type_key_name
            "#{options[:as]}_type"
          end
        
          def id_key_name
            "#{options[:as]}_id"
          end
      end
    end
  end
end