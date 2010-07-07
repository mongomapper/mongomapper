# encoding: UTF-8
# Almost all of this callback stuff is pulled directly from ActiveSupport
# in the interest of support rails 2 and 3 at the same time and is the
# same copyright as rails.
module MongoMapper
  module Plugins
    module Callbacks
      def self.configure(model)
        model.class_eval do
          extend ActiveModel::Callbacks
          
          define_model_callbacks :validation, :save, :create, :update, :destroy, :only => [ :before, :after ]
          define_model_callbacks :initialize, :find, :only => :after
        end
      end

      module InstanceMethods
        def valid?
          _run_validation_callbacks do
            super
          end
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
