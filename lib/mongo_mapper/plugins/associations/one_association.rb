# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class OneAssociation < BelongsToAssociation
        def embeddable?
          klass.embeddable?
        end

        def proxy_class
          @proxy_class ||= klass.embeddable? ? OneEmbeddedProxy : OneProxy
        end
        
        def setup(model)
          super
                    
          if options[:dependent] && !embeddable?
            association = self
            options = self.options

            model.after_destroy do
              proxy = self.get_proxy(association)
              
              unless proxy.nil?
                case options[:dependent]
                  when :destroy then proxy.destroy
                  when :delete  then proxy.delete
                  when :nullify then proxy.nullify
                end
              end
            end
          end
        end

        def autosave?
          options.fetch(:autosave, embeddable?)
        end
      end
    end
  end
end