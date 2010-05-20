# encoding: UTF-8
class Array
  def self.to_mongo(value)
    value = value.respond_to?(:lines) ? value.lines : value
    value.to_a
  end

  def self.from_mongo(value)
    value || []
  end
end

class Binary
  def self.to_mongo(value)
    if value.is_a?(BSON::Binary)
      value
    else
      value.nil? ? nil : BSON::Binary.new(value)
    end
  end

  def self.from_mongo(value)
    value
  end
end

class Boolean
  BOOLEAN_MAPPING = {
    true => true, 'true' => true, 'TRUE' => true, 'True' => true, 't' => true, 'T' => true, '1' => true, 1 => true, 1.0 => true,
    false => false, 'false' => false, 'FALSE' => false, 'False' => false, 'f' => false, 'F' => false, '0' => false, 0 => false, 0.0 => false, nil => nil
  }

  def self.to_mongo(value)
    if value.is_a?(Boolean)
      value
    else
      BOOLEAN_MAPPING[value]
    end
  end

  def self.from_mongo(value)
    !!value
  end
end

class Date
  def self.to_mongo(value)
    if value.nil? || value == ''
      nil
    else
      date = value.is_a?(Date) || value.is_a?(Time) ? value : Date.parse(value.to_s)
      Time.utc(date.year, date.month, date.day)
    end
  rescue
    nil
  end

  def self.from_mongo(value)
    value.to_date if value.present?
  end
end

class Float
  def self.to_mongo(value)
    value.nil? ? nil : value.to_f
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
    if value_to_i == 0 && value != value_to_i
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

class ObjectId
  def self.to_mongo(value)
    Plucky.to_object_id(value)
  end

  def self.from_mongo(value)
    value
  end
end

class Set
  def self.to_mongo(value)
    value.to_a
  end

  def self.from_mongo(value)
    Set.new(value || [])
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
    if value.nil? || value == ''
      nil
    else
      time_class = Time.try(:zone).present? ? Time.zone : Time
      time = value.is_a?(Time) ? value : time_class.parse(value.to_s)
      # strip milliseconds as Ruby does micro and bson does milli and rounding rounded wrong
      at(time.to_i).utc if time
    end
  end

  def self.from_mongo(value)
    if Time.try(:zone).present? && value.present?
      value.in_time_zone(Time.zone)
    else
      value
    end
  end
end

class BSON::ObjectID
  alias_method :original_to_json, :to_json

  def as_json(options=nil)
    to_s
  end

  def to_json(options = nil)
    as_json.to_json
  end
end