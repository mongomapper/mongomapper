module MongoMapper
  module Dirty
    DIRTY_SUFFIXES = ['_changed?', '_change', '_will_change!', '_was']
    
    def self.included(base)
      base.alias_method_chain :write_attribute, :dirty
      base.alias_method_chain :save,            :dirty
      base.alias_method_chain :save!,           :dirty
    end
    
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

    # List of keys with unsaved changes.
    #   person.changed # => []
    #   person.name = 'bob'
    #   person.changed # => ['name']
    def changed
      changed_keys.keys
    end

    # Map of changed attrs => [original value, new value].
    #   person.changes # => {}
    #   person.name = 'bob'
    #   person.changes # => { 'name' => ['bill', 'bob'] }
    def changes
      changed.inject({}) { |h, attribute| h[attribute] = key_change(attribute); h }
    end
    
    # Attempts to +save+ the record and clears changed keys if successful.
    def save_with_dirty(*args) #:nodoc:
      if status = save_without_dirty(*args)
        changed_keys.clear
      end
      status
    end

    # Attempts to <tt>save!</tt> the record and clears changed keys if successful.
    def save_with_dirty!(*args) #:nodoc:
      status = save_without_dirty!(*args)
      changed_keys.clear
      status
    end
    
    # <tt>reload</tt> the record and clears changed keys.
    # def reload_with_dirty(*args) #:nodoc:
    #   record = reload_without_dirty(*args)
    #   changed_keys.clear
    #   record
    # end

    private
      def clone_key_value(attribute_name)
        value = send(:read_attribute, attribute_name)
        value.duplicable? ? value.clone : value
      rescue TypeError, NoMethodError
        value
      end
      
      # Map of change <tt>attr => original value</tt>.
      def changed_keys
        @changed_keys ||= {}
      end

      # Handle <tt>*_changed?</tt> for +method_missing+.
      def key_changed?(attribute)
        changed_keys.include?(attribute)
      end

      # Handle <tt>*_change</tt> for +method_missing+.
      def key_change(attribute)
        [changed_keys[attribute], __send__(attribute)] if key_changed?(attribute)
      end

      # Handle <tt>*_was</tt> for +method_missing+.
      def key_was(attribute)
        key_changed?(attribute) ? changed_keys[attribute] : __send__(attribute)
      end

      # Handle <tt>*_will_change!</tt> for +method_missing+.
      def key_will_change!(attribute)
        changed_keys[attribute] = clone_key_value(attribute)
      end

      # Wrap write_attribute to remember original key value.
      def write_attribute_with_dirty(attribute, value)
        attribute = attribute.to_s

        # The key already has an unsaved change.
        if changed_keys.include?(attribute)
          old = changed_keys[attribute]
          changed_keys.delete(attribute) unless value_changed?(attribute, old, value)
        else
          old = clone_key_value(attribute)
          changed_keys[attribute] = old if value_changed?(attribute, old, value)
        end

        # Carry on.
        write_attribute_without_dirty(attribute, value)
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