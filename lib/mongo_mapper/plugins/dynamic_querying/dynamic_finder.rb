# encoding: UTF-8
module MongoMapper
  module Plugins
    module DynamicQuerying
      class DynamicFinder
        attr_reader :method, :attributes, :finder, :bang, :instantiator

        def initialize(method)
          @method = method
          @finder = :first
          @bang   = false
          match
        end

        def found?
          @finder.present?
        end

        def raise?
          bang == true
        end

        protected
          def match
            case method.to_s
              when /^find_(all_by|by)_([_a-zA-Z]\w*)$/
                @finder = :all if $1 == 'all_by'
                names = $2
              when /^find_by_([_a-zA-Z]\w*)\!$/
                @bang = true
                names = $1
              when /^find_or_(initialize|create)_by_([_a-zA-Z]\w*)$/
                @instantiator = $1 == 'initialize' ? :new : :create
                names = $2
              else
                @finder = nil
            end

            @attributes = names && names.split('_and_')
          end
      end
    end
  end
end