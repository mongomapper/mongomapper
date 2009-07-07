require 'observer'
require 'singleton'
require 'set'

module MongoMapper
  module Observing #:nodoc:
    def self.included(model)
      model.class_eval do
        extend Observable
        extend ClassMethods
      end      
    end

    module ClassMethods
      def observers=(*observers)
        @observers = observers.flatten
      end

      def observers
        @observers ||= []
      end

      def instantiate_observers
        return if @observers.blank?
        @observers.each do |observer|
          if observer.respond_to?(:to_sym) # Symbol or String
            observer.to_s.camelize.constantize.instance
          elsif observer.respond_to?(:instance)
            observer.instance
          else
            raise ArgumentError, "#{observer} must be a lowercase, underscored class name (or an instance of the class itself) responding to the instance method. Example: Person.observers = :big_brother # calls BigBrother.instance"
          end
        end
      end

      protected
        def inherited(subclass)
          super
          changed
          notify_observers :observed_class_inherited, subclass
        end
    end
  end

  class Observer
    include Singleton

    class << self
      def observe(*models)
        models.flatten!
        models.collect! { |model| model.is_a?(Symbol) ? model.to_s.camelize.constantize : model }
        define_method(:observed_classes) { Set.new(models) }
      end

      def observed_class
        if observed_class_name = name[/(.*)Observer/, 1]
          observed_class_name.constantize
        else
          nil
        end
      end
    end

    def initialize
      Set.new(observed_classes + observed_subclasses).each { |klass| add_observer! klass }
    end

    def update(observed_method, object) #:nodoc:
      send(observed_method, object) if respond_to?(observed_method)
    end

    def observed_class_inherited(subclass) #:nodoc:
      self.class.observe(observed_classes + [subclass])
      add_observer!(subclass)
    end

    protected
      def observed_classes
        Set.new([self.class.observed_class].compact.flatten)
      end
      
      def observed_subclasses
        observed_classes.sum([]) { |klass| klass.send(:subclasses) }
      end
      
      def add_observer!(klass)
        klass.add_observer(self)
      end
  end
end
