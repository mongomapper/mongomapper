module MongoMapper
  module Dirty
    DIRTY_SUFFIXES = ['_changed?', '_change', '_will_change!', '_was']
    
    def method_missing(method, *args, &block)
      if method.to_s =~ /(_changed\?|_change|_will_change!|_was)$/
        method_suffix = $1
        key = method.to_s.gsub(method_suffix, '')
        
        if key_names.include?(key)
          case method_suffix
            when '_changed?'
              key_changed?(key)
            when '_change'
              key_change(key)
            when '_will_change!'
              key_will_change!(key)
            when '_was'
              key_was(key)
          end
        else
          super
        end
      else
        super
      end
    end
    
    def changed?
      !changed_keys.empty?
    end

    def changed
      changed_keys.keys
    end

    def changes
      changed.inject({}) { |h, attribute| h[attribute] = key_change(attribute); h }
    end
    
    def initialize(attrs={})
      super(attrs)
      changed_keys.clear unless new?
    end

    def save(*args)
      if status = super
        changed_keys.clear
      end
      status
    end

    def save!(*args)
      status = super
      changed_keys.clear
      status
    end

    def reload(*args) #:nodoc:
      record = super
      changed_keys.clear
      record
    end

    private
      def clone_key_value(attribute_name)
        value = send(:read_attribute, attribute_name)
        value.duplicable? ? value.clone : value
      rescue TypeError, NoMethodError
        value
      end
      
      def changed_keys
        @changed_keys ||= {}
      end

      def key_changed?(attribute)
        changed_keys.include?(attribute)
      end

      def key_change(attribute)
        [changed_keys[attribute], __send__(attribute)] if key_changed?(attribute)
      end

      def key_was(attribute)
        key_changed?(attribute) ? changed_keys[attribute] : __send__(attribute)
      end

      def key_will_change!(attribute)
        changed_keys[attribute] = clone_key_value(attribute)
      end

      def write_attribute(attribute, value)
        attribute = attribute.to_s

        if changed_keys.include?(attribute)
          old = changed_keys[attribute]
          changed_keys.delete(attribute) unless value_changed?(attribute, old, value)
        else
          old = clone_key_value(attribute)
          changed_keys[attribute] = old if value_changed?(attribute, old, value)
        end

        super(attribute, value)
      end
      
      def value_changed?(key_name, old, value)
        key = _keys[key_name]
        
        if key.number? && value.blank?
          value = nil
        end
        
        old != value
      end
  end
end
