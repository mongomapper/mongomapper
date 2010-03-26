module MongoMapper
  module Plugins
    module Persistence
      module ClassMethods
        class Unsupported < MongoMapperError; end

        def connection(mongo_connection=nil)
          not_supported_by_embedded
          if mongo_connection.nil?
            @connection ||= MongoMapper.connection
          else
            @connection = mongo_connection
          end
          @connection
        end

        def set_database_name(name)
          not_supported_by_embedded
          @database_name = name
        end

        def database_name
          not_supported_by_embedded
          @database_name
        end

        def database
          not_supported_by_embedded
          if database_name.nil?
            MongoMapper.database
          else
            connection.db(database_name)
          end
        end

        def set_collection_name(name)
          not_supported_by_embedded
          @collection_name = name
        end

        def collection_name
          not_supported_by_embedded
          @collection_name ||= self.to_s.tableize.gsub(/\//, '.')
        end

        def collection
          not_supported_by_embedded
          database.collection(collection_name)
        end

        private
          def not_supported_by_embedded
            raise Unsupported.new('This is not supported for embeddable documents at this time.') if embeddable?
          end
      end

      module InstanceMethods
        def collection
          _root_document.class.collection
        end

        def database
          _root_document.class.database
        end
      end
    end
  end
end