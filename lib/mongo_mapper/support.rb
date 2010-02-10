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
  BOOLEAN_MAPPING = {
    true => true, 'true' => true, 'TRUE' => true, 'True' => true, 't' => true, 'T' => true, '1' => true, 1 => true, 1.0 => true,
    false => false, 'false' => false, 'FALSE' => false, 'False' => false, 'f' => false, 'F' => false, '0' => false, 0 => false, 0.0 => false, nil => false
  }
  
  def self.to_mongo(value)
    if value.is_a?(Boolean)
      value
    else
      v = BOOLEAN_MAPPING[value]
      v = value.to_s.downcase == 'true' if v.nil? # Check all mixed case spellings for true
      v
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
    if value.blank?
      nil
    elsif value.is_a?(Mongo::ObjectID)
      value
    else
      Mongo::ObjectID.from_string(value.to_s)
    end
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

class SymbolOperator
  attr_reader :field, :operator

  def initialize(field, operator, options={})
    @field, @operator = field, operator
  end unless method_defined?(:initialize)
end

class Symbol
  %w(gt lt gte lte ne in nin mod all size where exists asc desc).each do |operator|
    define_method(operator) do
      SymbolOperator.new(self, operator)
    end unless method_defined?(operator)
  end
end

class Time
  def self.to_mongo(value)
    if value.nil? || value == ''
      nil
    else
      time = value.is_a?(Time) ? value : MongoMapper.time_class.parse(value.to_s)
      # Convert time to milliseconds since BSON stores dates with that accurracy, but Ruby uses microseconds
      Time.at((time.to_f * 1000).round / 1000.0).utc if time
    end
  end
  
  def self.from_mongo(value)
    if MongoMapper.use_time_zone? && value.present?
      value.in_time_zone(Time.zone)
    else
      value
    end
  end
end

class Mongo::ObjectID
  alias_method :original_to_json, :to_json
  
  def to_json(options = nil)
    %Q("#{to_s}")
  end
end

module MongoMapper
  module Support
    autoload :DescendantAppends, 'mongo_mapper/support/descendant_appends'
    autoload :Find,              'mongo_mapper/support/find'
  end
end
