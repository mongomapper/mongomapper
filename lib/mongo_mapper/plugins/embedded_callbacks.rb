# encoding: UTF-8
module MongoMapper
  module Plugins
    module EmbeddedCallbacks
      extend ActiveSupport::Concern

      included do
        extend  ::ActiveModel::Callbacks

        define_model_callbacks :save, :create, :update, :destroy, :only => [:before, :after]
        define_model_callbacks :touch, :only => [:after]
      end

      def run_callbacks(callback, *args, &block)
        embedded_docs = []

        embedded_associations.each do |association|
          embedded_docs += Array(get_proxy(association).send(:load_target))
        end

        block = embedded_docs.inject(block) do |chain, doc|
          if doc.class.respond_to?("_#{callback}_callbacks")
            lambda { doc.run_callbacks(callback, *args, &chain) }
          else
            chain
          end
        end
        super callback, *args, &block
      end
    end
  end
end
