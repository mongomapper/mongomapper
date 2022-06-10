---
layout: documentation
title: Console
---

The MongoMapper Console is a great way to start playing with MongoMapper. Simply enter `mmconsole` in your terminal and you will be dropped into `irb` with MongoMapper included and your database set to 'mm-test'.

{% highlight ruby %}
Welcome to the MongoMapper Console!

Example 1:
  things = $db.collection("things")
  things.insert("name" => "Raw Thing")
  things.insert("name" => "Another Thing", "date" => Time.now)

  cursor = things.find("name" => "Raw Thing")
  puts cursor.next.inspect

Example 2:
  class Thing
    include MongoMapper::Document
    key :name, String, :required => true
    key :date, Time
  end

  thing = Thing.new
  thing.name = "My thing"
  thing.date = Time.now
  thing.save

  all_things = Thing.all
  puts all_things.map { |object| object.name }.inspect
ruby-1.9.2-p0 :001 >
{% endhighlight %}