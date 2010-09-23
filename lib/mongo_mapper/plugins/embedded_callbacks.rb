# encoding: UTF-8
module MongoMapper
  module Plugins
    module EmbeddedCallbacks
      def self.configure(model)
        model.class_eval do
          extend  ::ActiveModel::Callbacks
          include ::ActiveModel::Validations::Callbacks

          define_model_callbacks :validation, :save, :create, :update, :destroy, :only => [ :before, :after ]
          define_model_callbacks :initialize, :find, :only => :after
        end
      end

      module InstanceMethods
        def run_callbacks(callback, &block)
          embedded_docs = []

          embedded_associations.each do |association|
            embedded_docs += Array(get_proxy(association).target)
          end

          chain = embedded_docs.inject(block) do |block, doc|
            if doc.class.respond_to?("_#{callback}_callbacks")
              lambda { doc.run_callbacks(callback, &block) }
            else
              block
            end
          end
          super callback, &chain
        end
      end
    end
  end
end
