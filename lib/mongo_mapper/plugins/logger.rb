module MongoMapper
  module Logger
    module ClassMethods
      def logger
        MongoMapper.logger
      end
    end
    
    module InstanceMethods
      def logger
        self.class.logger
      end
    end
  end
end