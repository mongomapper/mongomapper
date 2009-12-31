module MongoMapper
  # This module is mixed into the Document module to provide call-backs before 
  # and after the following events:
  #
  # * save
  # * create
  # * update
  # * validation
  # ** every validation
  # ** validation when created
  # ** validation when updated
  # * destruction
  #
  # @see ActiveSupport::Callbacks
  module Callbacks
    def self.included(model) #:nodoc:
      model.class_eval do
        extend Observable
        include ActiveSupport::Callbacks

        callbacks = %w(
          before_save
          after_save
          before_create
          after_create
          before_update
          after_update
          before_validation
          after_validation
          before_validation_on_create
          after_validation_on_create
          before_validation_on_update
          after_validation_on_update
          before_destroy
          after_destroy
        )

        define_callbacks(*callbacks)

        callbacks.each do |callback|
          define_method(callback.to_sym) {}
        end
      end
    end

    def valid? #:nodoc:
      return false if callback(:before_validation) == false
      result = new? ? callback(:before_validation_on_create) : callback(:before_validation_on_update)
      return false if false == result

      result = super
      callback(:after_validation)

      new? ? callback(:after_validation_on_create) : callback(:after_validation_on_update)
      return result
    end

    # Here we override the +destroy+ method to allow for the +before_destroy+ 
    # and +after_destroy+ call-backs. Note that the +destroy+ call is aborted 
    # if the +before_destroy+ call-back returns +false+.
    #
    # @return the result of calling +destroy+ on the document
    def destroy #:nodoc:
      return false if callback(:before_destroy) == false
      result = super
      callback(:after_destroy)
      result
    end

    private
      def callback(method)
        result = run_callbacks(method) { |result, object| false == result }

        if result != false && respond_to?(method)
          result = send(method)
        end

        notify(method)
        return result
      end

      def notify(method) #:nodoc:
        self.class.changed
        self.class.notify_observers(method, self)
      end

      def create_or_update(*args) #:nodoc:
        return false if callback(:before_save) == false
        if result = super
          callback(:after_save)
        end
        result
      end

      def create(*args) #:nodoc:
        return false if callback(:before_create) == false
        result = super
        callback(:after_create)
        result
      end

      def update(*args) #:nodoc:
        return false if callback(:before_update) == false
        result = super
        callback(:after_update)
        result
      end
  end
end
