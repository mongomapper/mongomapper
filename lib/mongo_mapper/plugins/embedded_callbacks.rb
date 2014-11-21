# encoding: UTF-8
module MongoMapper
  module Plugins
    module EmbeddedCallbacks
      extend ActiveSupport::Concern

      included do
        extend  ::ActiveModel::Callbacks

        define_model_callbacks :save, :create, :update, :destroy, :only => [:before, :after]
        define_model_callbacks :initialize, :find, :touch, :only => [:after]

        proxy_callbacks(
          :before => [:save, :create, :update, :destroy],
          :after  => [:save, :create, :update, :destroy, :touch]
        )

        @embedded_callbacks_status = nil
      end

      module ClassMethods
        def define_callbacks(*args)
          embedded_callbacks_on if @embedded_callbacks_status.nil?
          super
        end

        def embedded_callbacks_on
          @embedded_callbacks_status = true
        end

        def embedded_callbacks_off
          @embedded_callbacks_status = false
        end

        def embedded_callbacks_on?
          !!@embedded_callbacks_status
        end

        def embedded_callbacks_off?
          !@embedded_callbacks_status
        end

        def proxy_callbacks(definition)
          definition.each do |prefix, suffixes|
            suffixes.each do |suffix|
              callback = "%s_%s" % [prefix, suffix]
              class_eval <<-CALLBACK, __FILE__, __LINE__ + 1
                class << self
                  alias_method :__original_#{callback}, :#{callback}

                  def #{callback}(*args, &block)
                    embedded_callbacks_on if @embedded_callbacks_status.nil?
                    __original_#{callback}(*args, &block)
                  end
                end
              CALLBACK
            end
          end
        end
      end

      def run_callbacks(callback, *args, &block)
        if self.class.embedded_callbacks_on? and embedded_associations.length > 0
          embedded_docs = embedded_associations.map do |association|
            Array(get_proxy(association).send(:load_target))
          end.flatten(1)

          block = embedded_docs.inject(block) do |chain, doc|
            if doc.class.respond_to?("_#{callback}_callbacks")
              lambda { doc.run_callbacks(callback, *args, &chain) }
            else
              chain
            end
          end
        end

        super callback, *args, &block
      end
    end
  end
end
