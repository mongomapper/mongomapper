# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class ManyDocumentsProxy < Collection
        include DynamicQuerying::ClassMethods

        def_delegators :query, *(Querying::Methods - [:each, :to_a, :size, :empty?])

        def replace(docs)
          load_target

          (target - docs).each do |t|
            case options[:dependent]
              when :destroy    then t.destroy
              when :delete_all then t.delete
              else t.update_attributes(self.foreign_key => nil)
            end
          end

          docs.each { |doc| prepare(doc).save }
          reset
        end

        def <<(*docs)
          ensure_owner_saved
          flatten_deeper(docs).each { |doc| prepare(doc).save }
          reset
        end
        alias_method :push, :<<
        alias_method :concat, :<<

        def build(attrs={})
          doc = klass.new(attrs)
          apply_scope(doc)
          yield doc if block_given?
          @target ||= [] unless loaded?
          @target << doc
          doc
        end

        def create(attrs={})
          doc = klass.new(attrs)
          apply_scope(doc)
          yield doc if block_given?
          doc.save
          reset
          doc
        end

        def create!(attrs={})
          doc = klass.new(attrs)
          apply_scope(doc)
          yield doc if block_given?
          doc.save!
          reset
          doc
        end

        def destroy_all(options={})
          all(options).each { |doc| doc.destroy }
          reset
        end

        def delete_all(options={})
          query(options).remove
          reset
        end

        def nullify
          all.each { |doc| doc.update_attributes(self.foreign_key => nil) }
          reset
        end

        def save_to_collection(options={})
          @target.each { |doc| doc.save(options) } if @target
        end

        def each(&block)
          load_target.each(&block)
        end

      protected

        def query(options={})
          klass.
            query(association.query_options).
            amend(options).amend(criteria)
        end

        def criteria
          {self.foreign_key => proxy_owner.id}
        end

        def find_target
          all
        end

        def ensure_owner_saved
          proxy_owner.save unless proxy_owner.persisted?
        end

        def prepare(doc)
          klass === doc ? apply_scope(doc) : build(doc)
        end

        def apply_scope(doc)
          criteria.each { |key, value| doc[key] = value }
          doc
        end

        def foreign_key
          options[:foreign_key] || proxy_owner.class.name.foreign_key
        end

      private

        def method_missing(method, *args, &block)
          if klass.respond_to?(method)
            result = klass.send(method, *args, &block)
            case result
            when Plucky::Query
              query.merge result

            # If we got a single record of this class as a result, return it
            when klass
              result

            # If we got an array of this class as a result, return it
            when Array
              if result[0].is_a? klass
                result
              else
                super
              end
            else
              super
            end
          else
            super
          end
        end
      end
    end
  end
end
