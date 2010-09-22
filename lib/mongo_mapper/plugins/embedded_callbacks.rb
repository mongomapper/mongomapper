# encoding: UTF-8
module MongoMapper
  module Plugins
    module EmbeddedCallbacks
      module InstanceMethods
        def run_callbacks(callback, &block)
          embedded_docs = []

          embedded_associations.each do |association|
            embedded_docs += Array(get_proxy(association).target)
          end

          chain = embedded_docs.inject(block) do |block, doc|
            lambda { doc.run_callbacks(callback, &block) }
          end
          super callback, &chain
        end
      end
    end
  end
end
