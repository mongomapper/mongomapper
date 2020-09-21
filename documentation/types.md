---
layout: documentation
title: Types
---

Because of MongoDB's ability to store rich documents, MongoMapper supports most of Ruby's data types out of the box, such as
[Array](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/array.rb),
[Float](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/float.rb),
[Hash](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/hash.rb),
[Integer](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/integer.rb),
[NilClass](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/nil_class.rb),
[Object](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/object.rb),
[String](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/string.rb),
[Symbol](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/symbol.rb), and
[Time](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/time.rb).

In addition to those, MongoMapper adds support for
[Binary](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/binary.rb),
[Boolean](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/boolean.rb),
[Date](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/date.rb),
[ObjectId](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/object_id.rb), and
[Set](http://github.com/mongomapper/mongomapper/blob/master/lib/mongo_mapper/extensions/set.rb) by serializing to and from Mongo safe types.

Custom Types
------------

The great thing about MongoMapper is that you can create your own types to make your models more pimp. All that is required to make your own type is to define the class and add the to\_mongo and from\_mongo class methods. For example, here is a type that always downcases strings when saving to the database:

{% highlight ruby %}
class DowncasedString
  def self.to_mongo(value)
    value.nil? ? nil : value.to_s.downcase
  end

  def self.from_mongo(value)
    to_mongo(value)
  end
end
{% endhighlight %}

Or, if you are curious about a slightly more complex example, here is a type that is used in MongoMapper's tests:

{% highlight ruby %}
class WindowSize
  attr_reader :width, :height

  def self.to_mongo(value)
    value.to_a
  end

  def self.from_mongo(value)
    value.is_a?(self) ? value : WindowSize.new(value)
  end

  def initialize(*args)
    @width, @height = args.flatten
  end

  def to_a
    [width, height]
  end

  def eql?(other)
    self.class.eql?(other.class) &&
       width == other.width &&
       height == other.height
  end
  alias :== :eql?
end
{% endhighlight %}

This example actually serializes to an array for storage in Mongo, but returns an actual WindowSize object after retrieving from the database.
