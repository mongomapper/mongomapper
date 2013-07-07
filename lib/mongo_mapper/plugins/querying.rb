# encoding: UTF-8
require 'mongo_mapper/plugins/querying/decorated_plucky_query'

module MongoMapper
  module Plugins
    module Querying
      extend ActiveSupport::Concern

      module ClassMethods
        extend Forwardable

        def_delegators :query, *Querying::Methods

        def find_by_id(id)
          find_one(:_id => id)
        end

        def first_or_create(args)
          first(args) || create(args.reject { |key, value| !key?(key) })
        end

        def first_or_new(args)
          first(args) || new(args.reject { |key, value| !key?(key) })
        end

        def create(*docs)
          initialize_each(*docs) do |doc|
            yield doc if block_given?
            doc.save
          end
        end

        def create!(*docs)
          initialize_each(*docs) do |doc|
            yield doc if block_given?
            doc.save!
          end
        end

        def update(*args)
          if args.length == 1
            update_multiple(args[0])
          else
            id, attributes = args
            update_single(id, attributes)
          end
        end

        # @api private for now
        def query(options={})
          query = MongoMapper::Plugins::Querying::DecoratedPluckyQuery.new(collection, :transformer => transformer)
          query.object_ids(object_id_keys)
          query.amend(options)
          query.model(self)
          query
        end
        alias_method :scoped, :query

        # @api private for now
        def criteria_hash(criteria={})
          Plucky::CriteriaHash.new(criteria, :object_ids => object_id_keys)
        end

        private
          def transformer
            @transformer ||= lambda { |doc| load(doc) }
          end

          def initialize_each(*docs)
            instances = []
            docs = [{}] if docs.blank?
            docs.flatten.each do |attrs|
              doc = new(attrs)
              yield(doc)
              instances << doc
            end
            instances.size == 1 ? instances[0] : instances
          end

          def update_single(id, attrs)
            if id.blank? || attrs.blank? || !attrs.is_a?(Hash)
              raise ArgumentError, "Updating a single document requires an id and a hash of attributes"
            end

            find(id).tap do |doc|
              doc.update_attributes(attrs)
            end
          end

          def update_multiple(docs)
            unless docs.is_a?(Hash)
              raise ArgumentError, "Updating multiple documents takes 1 argument and it must be hash"
            end

            instances = []
            docs.each_pair { |id, attrs| instances << update(id, attrs) }
            instances
          end
      end

      def save(options={})
        options.assert_valid_keys(:validate, :safe)
        create_or_update(options)
      end

      def save!(options={})
        options.assert_valid_keys(:safe)
        save(options) || raise(DocumentNotValid.new(self))
      end

      def destroy
        delete
      end

      def delete
        self.class.delete(id).tap { @_destroyed = true } if persisted?
      end

      private
        def create_or_update(options={})
          result = persisted? ? update(options) : create(options)
          result != false
        end

        def create(options={})
          save_to_collection(options)
        end

        def update(options={})
          save_to_collection(options)
        end

        def save_to_collection(options={})
          @_new = false
          collection.save(to_mongo, Utils.get_safe_options(options))
        end
    end
  end
end