# encoding: UTF-8
module MongoMapper
  module Plugins
    module Callbacks
      def self.configure(model)
        model.class_eval do
          extend  ::ActiveModel::Callbacks
          include ::ActiveModel::Validations::Callbacks
          
          define_model_callbacks :validation, :save, :create, :update, :destroy, :only => [ :before, :after ]
          define_model_callbacks :initialize, :find, :only => :after
        end
      end

      module InstanceMethods
        def valid?(context = nil)
          context ||= (new_record? ? :create : :update)
          super(context) && errors.empty?
        end

        def destroy
          _run_destroy_callbacks { super }
        end        

      private
        def create_or_update(*)
          _run_save_callbacks do
            super
          end
        end

        def create(*)
          _run_create_callbacks { super }
        end

        def update(*)
          _run_update_callbacks { super }
        end        
      end
    end
  end
end
