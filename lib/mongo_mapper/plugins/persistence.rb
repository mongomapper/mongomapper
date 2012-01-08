# encoding: UTF-8
module MongoMapper
  module Plugins
    module Persistence
      extend ActiveSupport::Concern

      module ClassMethods
        def connection(mongo_connection=nil)
          assert_supported
          if mongo_connection.nil?
            @connection ||= MongoMapper.connection
          else
            @connection = mongo_connection
          end
          @connection
        end

        def set_database_name(name)
          assert_supported
          @database_name = name
        end

        def database_name
          assert_supported
          @database_name
        end

        def database
          assert_supported
          if database_name.nil?
            MongoMapper.database
          else
            connection.db(database_name)
          end
        end

        def set_collection_name(name)
          assert_supported
          @collection_name = name
        end

        def collection_name
          assert_supported
          @collection_name ||= self.to_s.tableize.gsub(/\//, '.')
        end

        def collection
          assert_supported
          database.collection(collection_name)
        end

        private
          def assert_supported
            if embeddable?
              raise NotSupported.new('This is not supported for embeddable documents at this time.')
            end
          end
      end

      def collection
        _root_document.class.collection
      end

      def database
        _root_document.class.database
      end
    end
  end
end