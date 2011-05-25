# encoding: UTF-8
module MongoMapper
  module Plugins
    module EmbeddedCallbacks
      extend ActiveSupport::Concern

      included do
        extend  ::ActiveModel::Callbacks

        define_model_callbacks :validation, :save, :create, :update, :destroy, :only => [:before, :after]
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
