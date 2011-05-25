# encoding: UTF-8
module MongoMapper
  module Plugins
    module EmbeddedCallbacks
      extend ActiveSupport::Concern

      included do
        extend  ::ActiveModel::Callbacks
        include ::ActiveModel::Validations::Callbacks

        define_model_callbacks :save, :create, :update, :destroy, :only => [:before, :after]
      end

      module InstanceMethods
        def run_callbacks(callback, &block)
          embedded_docs = []

          embedded_associations.each do |association|
            embedded_docs += Array(get_proxy(association).send(:load_target))
          end

          block = embedded_docs.inject(block) do |chain, doc|
            if doc.class.respond_to?("_#{callback}_callbacks")
              lambda { doc.run_callbacks(callback, &chain) }
            else
              chain
            end
          end
          super callback, &block
        end
      end
    end
  end
end

# Need to monkey patch ActiveModel for now since it uses the internal
# _run_validation_callbacks, which is impossible to override due to the
# way ActiveSupport::Callbacks is implemented.
ActiveModel::Validations::Callbacks.class_eval do
  def run_validations!
    run_callbacks(:validation) { super }
  end
end
