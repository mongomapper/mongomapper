# encoding: UTF-8
require 'forwardable'

module MongoMapper
  module Plugins
    module Associations
      class Proxy
        extend Forwardable

        class << self
          def define_proxy_method(method)
            define_method(method) do |*args, &block|
              proxy_method(method, *args, &block)
            end
          end
        end

        attr_reader :proxy_owner, :association, :target

        alias_method :proxy_respond_to?, :respond_to?
        alias_method :proxy_extend, :extend
        alias_method :proxy_association, :association

        def_delegators :proxy_association, :klass, :options
        def_delegator  :klass, :collection

        def initialize(owner, association)
          @proxy_owner, @association, @loaded = owner, association, false
          Array(association.options[:extend]).each { |ext| proxy_extend(ext) }
          reset
        end

        [
          :is_a?,
          :to_mongo,
          :==,
          :!=,
          :nil?,
          :blank?,
          :present?,
          # Active support in rails 3 beta 4 can override to_json after this is loaded,
          # at least when run in mongomapper tests. The implementation was changed in master
          # some time after this, so not sure whether this is still a problem.
          #
          # In rails 2, this isn't a problem however it also solves an issue where
          # to_json isn't forwarded because it supports to_json itself
          :to_json,
          # see comments to to_json
          :as_json,
        ].each do |m|
          define_proxy_method(m)
        end

        def inspect
          load_target
          "#<#{self.class.inspect}:#{object_id} #{@target.inspect}>"
        end

        def loaded?
          @loaded
        end

        def loaded
          @loaded = true
        end

        def reload
          reset
          load_target
          self unless target.nil?
        end

        # :nocov:
        def replace(v)
          raise NotImplementedError
        end
        # :nocov:

        def reset
          @loaded = false
          @target = nil
        end

        def respond_to?(*args)
          super || (load_target && target.respond_to?(*args))
        end

        def read
          load_target
          @target
        end

        def write(value)
          replace(value)
          read
        end

        def proxy_method(method, *args, &block)
          load_target
          target.public_send(method, *args, &block)
        end

      protected

        def load_target
          if !loaded? || stale_target?
            if @target.is_a?(Array) && @target.any?
              @target = find_target + @target.find_all { |record| !record.persisted? }
            else
              @target = find_target
            end
            loaded
          end
          @target
        rescue MongoMapper::DocumentNotFound
          reset
        end

        # :nocov:
        def find_target
          raise NotImplementedError
        end
        # :nocov:

        def flatten_deeper(array)
          array.collect do |element|
            (element.respond_to?(:flatten) && !element.is_a?(Hash)) ? element.flatten : element
          end.flatten
        end

      private

        def stale_target?
          false
        end

        def define_proxy_method(method)
          metaclass = class << self; self; end
          metaclass.class_eval do
            define_proxy_method(method)
          end
        end

        def define_and_call_proxy_method(method, *args, &block)
          define_proxy_method(method)
          public_send(method, *args, &block)
        end

        def method_missing(method, *args, &block)
          # load the target just in case it isn't loaded
          load_target

          # only define the method if the target has the method
          # NOTE: include private methods!
          if target.respond_to?(method, true)
            define_and_call_proxy_method(method, *args, &block)
          else
            super
          end
        end
      end
    end
  end
end
