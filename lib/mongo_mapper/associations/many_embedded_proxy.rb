module MongoMapper
  module Associations
    class ManyEmbeddedProxy < Proxy
      def replace(v)
        @_values = v.map { |e| e.kind_of?(EmbeddedDocument) ? e.attributes : e }
        reset
      end
      
      def build(opts={})
        owner = @owner
        child = @association.klass.new(opts)
        assign_parent_reference(child)
        child._root_document = owner
        self << child
        child
      end
      
      def find(opts)
        case opts
        when :all
          self
        when String
          if load_target
            child = @target.detect {|item| item.id == opts}
            assign_parent_reference(child)
            child
          end
        end
      end

      def <<(*docs)
        if load_target
          root = @owner._root_document || @owner
          docs.each do |doc|
            doc._root_document = root
            @target << doc
          end
        end
      end
      alias_method :push, :<<
      alias_method :concat, :<<

      protected
        def find_target
          (@_values || []).map do |e|
            child = @association.klass.new(e)
            assign_parent_reference(child)
            child
          end
        end
        
      private
      
        def assign_parent_reference(child)
          return unless child && @owner
          return if @owner.class.name.blank?
          owner = @owner
          child.class_eval do
            define_method(owner.class.name.underscore) do
              owner
            end
          end
        end
      
    end
  end
end
