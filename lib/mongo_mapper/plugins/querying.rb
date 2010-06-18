# encoding: UTF-8
require 'mongo_mapper/plugins/querying/decorator'
require 'mongo_mapper/plugins/querying/plucky_methods'

module MongoMapper
  module Plugins
    module Querying
      module ClassMethods
        include PluckyMethods

        def find_each(opts={})
          super(opts).each { |doc| yield load(doc) }
        end

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
          initialize_each(*docs) { |doc| doc.save }
        end

        def create!(*docs)
          initialize_each(*docs) { |doc| doc.save! }
        end

        def update(*args)
          if args.length == 1
            update_multiple(args[0])
          else
            id, attributes = args
            update_single(id, attributes)
          end
        end

        def delete(*ids)
          query(:_id => ids.flatten).remove
        end

        def delete_all(options={})
          query(options).remove
        end

        def destroy(*ids)
          find_some!(ids.flatten).each(&:destroy)
        end

        def destroy_all(options={})
          find_each(options) { |document| document.destroy }
        end

        # @api private for now
        def query(options={})
          Plucky::Query.new(collection).tap do |query|
            query.extend(Decorator)
            query.object_ids(object_id_keys)
            query.update(options)
            query.model(self)
          end
        end

        # @api private for now
        def criteria_hash(criteria={})
          Plucky::CriteriaHash.new(criteria, :object_ids => object_id_keys)
        end

        private
          def find_some(ids, options={})
            query = query(options).update(:_id => ids.flatten.compact.uniq)
            find_many(query.to_hash).compact
          end

          def find_some!(ids, options={})
            ids  = ids.flatten.compact.uniq
            docs = find_some(ids, options)

            if ids.size != docs.size
              raise DocumentNotFound, "Couldn't find all of the ids (#{ids.to_sentence}). Found #{docs.size}, but was expecting #{ids.size}"
            end

            docs
          end

          # All query methods that load documents pass through find_one or find_many
          def find_one(options={})
            query(options).first
          end

          # All query methods that load documents pass through find_one or find_many
          def find_many(options)
            query(options).all
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

      module InstanceMethods
        def save(options={})
          options.assert_valid_keys(:validate, :safe)
          options.reverse_merge!(:validate => true)
          !options[:validate] || valid? ? create_or_update(options) : false
        end

        def save!(options={})
          options.assert_valid_keys(:safe)
          save(options) || raise(DocumentNotValid.new(self))
        end

        def destroy
          delete
        end

        def delete
          @_destroyed = true
          self.class.delete(id) unless new?
        end

        private
          def create_or_update(options={})
            result = new? ? create(options) : update(options)
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
            collection.save(to_mongo, :safe => options[:safe])
          end
      end
    end
  end
end