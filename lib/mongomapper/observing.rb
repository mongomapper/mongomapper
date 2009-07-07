require 'observer'
require 'singleton'
require 'set'

module MongoMapper
  module Observing #:nodoc:
    def self.included(model)
      model.class_eval do
        extend Observable
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
      Set.new(observed_classes).each { |klass| add_observer! klass }
    end

    def update(observed_method, object) #:nodoc:
      send(observed_method, object) if respond_to?(observed_method)
    end

    protected
      def observed_classes
        Set.new([self.class.observed_class].compact.flatten)
      end
      
      def add_observer!(klass)
        klass.add_observer(self)
      end
  end
end
