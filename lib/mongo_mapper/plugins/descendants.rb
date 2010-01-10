module MongoMapper
  module Plugins
    module Descendants
      module ClassMethods
        def inherited(descendant)
          (@descendants ||= []) << descendant
          super
        end

        def descendants
          @descendants
        end
      end
    end
  end
end