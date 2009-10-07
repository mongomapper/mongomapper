class BasicObject #:nodoc:
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|^methods$|instance_eval|proxy_|^object_id$)/ }
end unless defined?(BasicObject)

class Array
  def self.to_mongo(value)
    value.to_a
  end
  
  def self.from_mongo(value)
    value || []
  end
end

class Binary
  def self.to_mongo(value)
    if value.is_a?(ByteBuffer)
      value
    else
      value.nil? ? nil : ByteBuffer.new(value)
    end
  end
  
  def self.from_mongo(value)
    value
  end
end

class Boolean
  def self.to_mongo(value)
    if value.is_a?(Boolean)
      value
    else
      ['true', 't', '1'].include?(value.to_s.downcase)
    end
  end
  
  def self.from_mongo(value)
    !!value
  end
end

class Date
  def self.to_mongo(value)
    date = Date.parse(value.to_s)
    Time.utc(date.year, date.month, date.day)
  rescue
    nil
  end
  
  def self.from_mongo(value)
    value.to_date if value.present?
  end
end

class Float
  def self.to_mongo(value)
    value.to_f
  end
end

class Hash
  def self.from_mongo(value)
    HashWithIndifferentAccess.new(value || {})
  end
  
  def to_mongo
    self
  end
end

class Integer
  def self.to_mongo(value)
    value_to_i = value.to_i
    if value_to_i == 0
      value.to_s =~ /^(0x|0b)?0+/ ? 0 : nil
    else
      value_to_i
    end
  end
end

class NilClass
  def to_mongo(value)
    value
  end
  
  def from_mongo(value)
    value
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
  
  def self.to_mongo(value)
    value
  end
  
  def self.from_mongo(value)
    value
  end
end

class String
  def self.to_mongo(value)
    value.nil? ? nil : value.to_s
  end
  
  def self.from_mongo(value)
    value.nil? ? nil : value.to_s
  end
end

class Time
  def self.to_mongo(value)
    to_utc_time(value)
  end
  
  def self.from_mongo(value)
    if Time.respond_to?(:zone) && Time.zone && value.present?
      value.in_time_zone(Time.zone)
    else
      value
    end
  end
  
  def self.to_utc_time(value)
    to_local_time(value).try(:utc)
  end
  
  # make sure we have a time and that it is local
  def self.to_local_time(value)
    if Time.respond_to?(:zone) && Time.zone
      Time.zone.parse(value.to_s)
    else
      Time.parse(value.to_s)
    end
  end
end