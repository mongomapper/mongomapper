# encoding: UTF-8
module MongoMapper
  module Plugins
    module EmbeddedCallbacks
      extend ActiveSupport::Concern

      included do
        extend ::ActiveModel::Callbacks
        
        define_model_callbacks :save, :create, :update, :destroy, :only => [:before, :after]
      end

      module InstanceMethods
        
        def embedded_documents
          embedded_docs = []

          embedded_associations.each do |association|
            embedded_docs += Array(get_proxy(association).send(:load_target))
          end
          embedded_docs
        end

        def run_callbacks(callback, *args, &block)
          callbacks = Fiber.new do
                        block = embedded_documents.inject(block) do |chain, doc|
                          if doc.class.respond_to?("_#{callback}_callbacks")
                            lambda { doc.run_callbacks(callback, *args, &chain) }
                          else
                            chain
                          end
                        end
                        Fiber.yield super callback, *args, &block
                  end
            callbacks.resume(callback, *args, &block)
        end
      end
    end
  end
end
