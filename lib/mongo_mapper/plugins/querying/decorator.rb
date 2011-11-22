# encoding: UTF-8
module MongoMapper
  module Plugins
    module Querying
      module Decorator
        include DynamicQuerying::ClassMethods

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
        
        %w(first last all where find_each exist? exists? count).each do |meth|
          define_method(meth.to_sym) do |*args, &block|
            rewrite_keys_with_aliases(args)
            super(*args, &block)
          end
        end
        
        %w(fields sort).each do |meth|
          define_method(meth.to_sym) do |*args, &block|
            args = rewrite_args_with_aliases(args)
            super(*args, &block)
          end
        end
                
        private
          def method_missing(method, *args, &block)
            return super unless model.respond_to?(method)
            result = model.send(method, *args, &block)
            return super unless result.is_a?(Plucky::Query)
            merge(result)
          end
                    
          def rewrite_keys_with_aliases(args)
            if args[0].is_a? Hash and model.respond_to? :alias_for_key_name
              aliased_attrs = {}
              args[0].each do |k,v| 
                if k.is_a? SymbolOperator
                  aliased_attrs[SymbolOperator.new( model.alias_for_key_name(k.field.to_s).to_sym, k.operator )] = v
                else
                  aliased_attrs[model.alias_for_key_name(k)] = v
                end
              end
              args[0] = aliased_attrs
            end
          end
          
          def rewrite_args_with_aliases(args)
            if args.is_a? Array and model.respond_to? :alias_for_key_name
              aliased_args = []
              args.each do |a|
                if a.is_a? SymbolOperator
                  aliased_args << SymbolOperator.new( model.alias_for_key_name(a.field.to_s).to_sym, a.operator )
                else
                  aliased_args << model.alias_for_key_name(a)
                end
              end
            end
            aliased_args
          end
      end
    end
  end
end