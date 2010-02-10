module MongoMapper
  module Plugins
    module Associations
      class Proxy
        alias :proxy_respond_to? :respond_to?
        alias :proxy_extend :extend

        instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|proxy_|^object_id$)/ }

        attr_reader :owner, :association, :target

        alias :proxy_owner :owner
        alias :proxy_target :target
        alias :proxy_association :association

        delegate :klass, :to => :proxy_association
        delegate :options, :to => :proxy_association
        delegate :collection, :to => :klass

        def initialize(owner, association)
          @owner, @association, @loaded = owner, association, false
          Array(association.options[:extend]).each { |ext| proxy_extend(ext) }
          reset
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
            @target = find_target unless loaded?
            loaded
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
