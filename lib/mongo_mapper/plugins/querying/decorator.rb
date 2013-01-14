# encoding: UTF-8
module MongoMapper
  module Plugins
    module Querying
      Methods = Plucky::Methods + [:delete, :delete_all, :destroy, :destroy_all, :find!]

      module Decorator
        include DynamicQuerying::ClassMethods

        def delete(*ids)
          where(:_id => ids.flatten).remove
        end

        def delete_all(options = {})
          where(options).remove
        end

        def destroy(*ids)
          [find!(*ids.flatten.compact.uniq)].flatten.each { |doc| doc.destroy }
        end

        def destroy_all(options={})
          find_each(options) { |document| document.destroy }
        end

        def model(model=nil)
          return @model if model.nil?
          @model = model
          self
        end

        def find!(*ids)
          raise DocumentNotFound, "Couldn't find without an ID" if ids.size == 0

          find(*ids).tap do |result|
            if result.nil? || ids.size != Array(result).size
              raise DocumentNotFound, "Couldn't find all of the ids (#{ids.join(',')}). Found #{Array(result).size}, but was expecting #{ids.size}"
            end
          end
        end
        
        # Added To Master by DS.
        # These methods interact with driver, need to use abbreviation, not full attribute name.
        # Plucky performs the following aliases (we don't need the aliased method):
        #  alias_method :each,   :find_each
        #  alias_method :first,  :find_one
        #  alias_method :size,   :count
        #  alias_method :exist?, :exists?
        #  alias_method :filter, :where
        #  alias_method :to_a,   :all
        %w(last all where find_one find_each exists? count).each do |meth|
          define_method(meth.to_sym) do |*args, &block|
            rewrite_keys_with_abbr(args)
            super(*args, &block)
          end
        end
        
        # Added To Master by DS.
        # These methods interact with driver, need to use abbreviation, not full attribute name.
        # Plucky performs the following aliases (we don't need the aliased method):
        #  alias_method :order,  :sort
        %w(fields sort).each do |meth|
          define_method(meth.to_sym) do |*args, &block|
            args = rewrite_args_with_abbr(args)
            super(*args, &block)
          end
        end
                
        private
          def method_missing(method, *args, &block)
            return super unless model.respond_to?(method)
            result = model.send(method, *args, &block)
            if result.is_a?(Plucky::Query)
              merge(result)
            else
              result
            end
          end
          
          # Added To Master by DS.
          # These methods interact with driver, need to use abbreviation, not full attribute name.          
          def rewrite_keys_with_abbr(args)
            if args[0].is_a? Hash and model.respond_to? :abbr_for_key_name
              abbreviated_attrs = {}
              args[0].each do |k,v| 
                if k.is_a? SymbolOperator
                  abbreviated_attrs[SymbolOperator.new( model.abbr_for_key_name(k.field.to_s).to_sym, k.operator )] = v
                else
                  abbreviated_attrs[model.abbr_for_key_name(k)] = v
                end
              end
              args[0] = abbreviated_attrs
            end
          end
          
          # Added To Master by DS.
          # These methods interact with driver, need to use abbreviation, not full attribute name.
          def rewrite_args_with_abbr(args)
            if args.is_a? Array and model.respond_to? :abbr_for_key_name
              abbreviated_args = []
              args.each do |a|
                if a.is_a? SymbolOperator
                  abbreviated_args << SymbolOperator.new( model.abbr_for_key_name(a.field.to_s).to_sym, a.operator )
                else
                  abbreviated_args << model.abbr_for_key_name(a)
                end
              end
            end
            abbreviated_args
          end
      end
    end
  end
end