# encoding: UTF-8
require 'forwardable'
module MongoMapper
  module Plugins
    module Associations
      class Proxy
        extend Forwardable

        alias :proxy_respond_to? :respond_to?
        alias :proxy_extend :extend

        instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|proxy_|^object_id$)/ }

        attr_reader :proxy_owner, :association, :target

        alias :proxy_target :target
        alias :proxy_association :association

        def_delegators :proxy_association, :klass, :options
        def_delegator  :klass, :collection

        def initialize(owner, association)
          @proxy_owner, @association, @loaded = owner, association, false
          Array(association.options[:extend]).each { |ext| proxy_extend(ext) }
          reset
        end

        # Active support in rails 3 beta 4 can override to_json after this is loaded,
        # at least when run in mongomapper tests. The implementation was changed in master 
        # some time after this, so not sure whether this is still a problem.
        #
        # In rails 2, this isn't a problem however it also solves an issue where
        # to_json isn't forwarded because it supports to_json itself
        def to_json(*options)
          load_target
          target.to_json(*options)
        end

        # see comments to to_json
        def as_json(*options)
          load_target
          target.as_json(*options)
        end
        
        def inspect
          load_target
          target.inspect
        end

        def loaded?
          @loaded
        end

        def loaded
          @loaded = true
        end

        def nil?
          load_target
          target.nil?
        end

        def blank?
          load_target
          target.blank?
        end

        def present?
          load_target
          target.present?
        end

        def reload
          reset
          load_target
          self unless target.nil?
        end

        def replace(v)
          raise NotImplementedError
        end

        def reset
          @loaded = false
          @target = nil
        end

        def respond_to?(*args)
          proxy_respond_to?(*args) || (load_target && target.respond_to?(*args))
        end

        def send(method, *args)
          if proxy_respond_to?(method)
            super
          else
            load_target
            target.send(method, *args)
          end
        end

        def ===(other)
          load_target
          other === target
        end

        protected
          def method_missing(method, *args, &block)
            if load_target
              if block_given?
                target.send(method, *args)  { |*block_args| block.call(*block_args) }
              else
                target.send(method, *args)
              end
            end
          end

          def load_target
            unless loaded?
              if @target.is_a?(Array) && @target.any?
                @target = find_target + @target.find_all { |record| record.new? }
              else
                @target = find_target
              end
              loaded
            end
            @target
          rescue MongoMapper::DocumentNotFound
            reset
          end

          def find_target
            raise NotImplementedError
          end

          def flatten_deeper(array)
            array.collect do |element|
              (element.respond_to?(:flatten) && !element.is_a?(Hash)) ? element.flatten : element
            end.flatten
          end
      end
    end
  end
end
