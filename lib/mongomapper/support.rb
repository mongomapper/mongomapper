class BasicObject #:nodoc:
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|instance_eval|proxy_|^object_id$)/ }
end unless defined?(BasicObject)

class Boolean
  def self.mm_typecast(value)
    ['true', 't', '1'].include?(value.to_s.downcase)
  end
end

class Object
  # The hidden singleton lurks behind everyone
  def metaclass
    class << self; self end
  end

  def meta_eval(&blk)
    metaclass.instance_eval(&blk)
  end

  # Adds methods to a metaclass
  def meta_def(name, &blk)
    meta_eval { define_method(name, &blk) }
  end

  # Defines an instance method within a class
  def class_def(name, &blk)
    class_eval { define_method(name, &blk) }
  end
end