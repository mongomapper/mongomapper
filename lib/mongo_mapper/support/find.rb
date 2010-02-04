module MongoMapper
  module Support
    # @api private
    module Find
      def dynamic_find(finder, args)
        attributes = {}

        finder.attributes.each_with_index do |attr, index|
          attributes[attr] = args[index]
        end

        options = args.extract_options!.merge(attributes)

        if result = send(finder.finder, options)
          result
        else
          if finder.raise?
            raise DocumentNotFound, "Couldn't find Document with #{attributes.inspect} in collection named #{collection.name}"
          end

          if finder.instantiator
            self.send(finder.instantiator, attributes)
          end
        end
      end

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

      protected
        def method_missing(method, *args, &block)
          finder = DynamicFinder.new(method)

          if finder.found?
            dynamic_find(finder, args)
          else
            super
          end
        end
    end
  end
end