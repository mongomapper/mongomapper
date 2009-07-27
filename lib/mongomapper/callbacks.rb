module MongoMapper
  module Callbacks    
    def self.included(model) #:nodoc:
      model.class_eval do
        extend Observable
        include ActiveSupport::Callbacks
        
        define_callbacks *%w(
          before_save after_save before_create after_create before_update after_update before_validation
          after_validation before_validation_on_create after_validation_on_create before_validation_on_update
          after_validation_on_update before_destroy after_destroy
        )
        
        [:create_or_update, :valid?, :create, :update, :destroy].each do |method|
          alias_method_chain method, :callbacks
        end
      end
    end

    def before_save() end

    def after_save()  end
    def create_or_update_with_callbacks #:nodoc:
      return false if callback(:before_save) == false
      if result = create_or_update_without_callbacks
        callback(:after_save)
      end
      result
    end
    private :create_or_update_with_callbacks

    def before_create() end

    def after_create() end
    def create_with_callbacks #:nodoc:
      return false if callback(:before_create) == false
      result = create_without_callbacks
      callback(:after_create)
      result
    end
    private :create_with_callbacks

    def before_update() end

    def after_update() end

    def update_with_callbacks(*args) #:nodoc:
      return false if callback(:before_update) == false
      result = update_without_callbacks(*args)
      callback(:after_update)
      result
    end
    private :update_with_callbacks

    def before_validation() end

    def after_validation() end

    def before_validation_on_create() end

    def after_validation_on_create()  end

    def before_validation_on_update() end

    def after_validation_on_update()  end

    def valid_with_callbacks? #:nodoc:
      return false if callback(:before_validation) == false
      result = new? ? callback(:before_validation_on_create) : callback(:before_validation_on_update)
      return false if false == result
      
      result = valid_without_callbacks?
      callback(:after_validation)
      
      new? ? callback(:after_validation_on_create) : callback(:after_validation_on_update)
      return result
    end

    def before_destroy() end

    def after_destroy()  end
    def destroy_with_callbacks #:nodoc:
      return false if callback(:before_destroy) == false
      result = destroy_without_callbacks
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
  end
end
