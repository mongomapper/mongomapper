# encoding: UTF-8
require 'set'

module MongoMapper
  module Plugins
    module IdentityMap
      extend ActiveSupport::Concern

      def self.enabled=(flag)
        Thread.current[:mongo_mapper_identity_map_enabled] = flag
      end

      def self.enabled
        Thread.current[:mongo_mapper_identity_map_enabled]
      end

      def self.enabled?
        enabled == true
      end

      def self.repository
        Thread.current[:mongo_mapper_identity_map] ||= {}
      end

      def self.clear
        repository.clear
      end

      def self.include?(document)
        repository.key?(IdentityMap.key(document.class, document._id))
      end

      def self.key(model, id)
        "#{model.single_collection_root.name}:#{id}"
      end

      def self.use
        old, self.enabled = enabled, true

        yield if block_given?
      ensure
        self.enabled = old
        clear
      end

      def self.without
        old, self.enabled = enabled, false

        yield if block_given?
      ensure
        self.enabled = old
      end

      module ClassMethods
        # Private - Looks for a document in the identity map
        def get_from_identity_map(id)
          IdentityMap.repository[IdentityMap.key(self, id)].tap do |doc|
            if MongoMapper.logger and doc
              MongoMapper.logger.info "MONGODB IDENTITY MAP HIT FOR #{id}" if IdentityMap.enabled? and MongoMapper.logger
            else
              MongoMapper.logger.info "MONGODB IDENTITY MAP MISS #{id} :-(" if IdentityMap.enabled? and MongoMapper.logger
            end
          end
        end

        module IdentityMapQueryMethods
          
          # def all(opts={})
            # MongoMapper.logger.info ">>> in all"
            # query = clone.amend(opts)
            # super.tap do |docs|
              # model.remove_documents_from_map(docs) if query.fields?
            # end
          # end
          
          def all(opts={})
            MongoMapper.logger.info ">>> in all" if MongoMapper.logger
            query = clone.amend(opts)
            [].tap do |docs|
              if IdentityMap.enabled? && query.simple?
                if query[:_id].is_a?(Hash) && ids = query[:_id]["$in"]
                  if query[:sort].nil?
                    ids.each do |id|
                      if doc = model.get_from_identity_map(id)
                        docs << doc 
                        ids.delete id
                      end
                    end
                    break docs if ids.empty?
                  end
                else break [find_one(opts)].compact
                end
              end
              find_each(query.criteria) { |doc| docs << doc }
            end
          end

          def find_one(opts={})
            MongoMapper.logger.info ">>> in find_one" if MongoMapper.logger
            query = clone.amend(opts)

            if IdentityMap.enabled? && query.simple? && (document = model.get_from_identity_map(query[:_id]))
              document
            else
              super.tap do |doc|
                model.remove_documents_from_map(doc) if query.fields?
              end
            end
          end
          
          def find_each(opts={}, &block)
            query = clone.amend(opts)
            super(opts) do |doc|
              model.remove_documents_from_map(doc) if query.fields?
              block.call(doc) unless block.nil?
            end
          end
          
          
        end
        
        

        def query(opts={})
          MongoMapper.logger.info ">>> in query" if MongoMapper.logger
          super.extend(IdentityMapQueryMethods)
        end

        def remove_documents_from_map(*documents)
          documents.flatten.compact.each do |document|
            document.remove_from_identity_map
          end
        end

        def load(attrs)
          if MongoMapper.logger
            MongoMapper.logger.info ">>> in load"
            MongoMapper.logger.info ">>> but leaving because attrs.nil?" if attrs.nil?
          end
          return nil if attrs.nil?
          document = get_from_identity_map(attrs['_id'])

          if document.nil?
            document = super
            document.add_to_identity_map
          end

          document
        end
      end

      def save(*args)
        super.tap { |result| add_to_identity_map if result }
      end

      def delete
        super.tap { remove_from_identity_map }
      end

      def add_to_identity_map
        if IdentityMap.enabled?
          MongoMapper.logger.info ">>> adding in add_to_identity_map" if MongoMapper.logger
          key = IdentityMap.key(self.class, _id)
          IdentityMap.repository[key] = self
        end
      end

      def remove_from_identity_map
        if IdentityMap.enabled?
          MongoMapper.logger.info ">>> removing in remove_from_identity_map" if MongoMapper.logger
          key = IdentityMap.key(self.class, _id)
          IdentityMap.repository.delete(key)
        end
      end
    end
  end
end