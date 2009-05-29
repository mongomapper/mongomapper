module MongoMapper
  module SubDocument
    class NotImplemented < StandardError; end
    
    def self.included(model)
      MongoMapper.add_subdocument model
      
      model.class_eval do
        include MongoMapper::Document
        include InstanceMethods
        extend ClassMethods
      end
      
      model.instance_variable_set("@keys", HashWithIndifferentAccess.new)
    end
    
    module ClassMethods
      def find(*args);            raise NotImplemented; end
      def count(*args);           raise NotImplemented; end
      def create(*args);          raise NotImplemented; end
      def update(*args);          raise NotImplemented; end
      def delete(*args);          raise NotImplemented; end
      def delete_all(*args);      raise NotImplemented; end
      def destroy(*args);         raise NotImplemented; end
      def destroy_all(*args);     raise NotImplemented; end
      def collection(*args);      raise NotImplemented; end
    end                                 
                                        
    module InstanceMethods
      def collection(*args);        raise NotImplemented; end
      def new?(*args);              raise NotImplemented; end
      def save(*args);              raise NotImplemented; end
      def update_attributes(*args); raise NotImplemented; end
      def destroy(*args);           raise NotImplemented; end
      def id(*args);                raise NotImplemented; end
      
      def ==(other)
        self.attributes.all? do |attr|
          key, value = attr
          value == other[key]
        end
      end
    end
  end
end