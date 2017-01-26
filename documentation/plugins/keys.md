---
layout: documentation
title: Keys
---

Since MongoDB is schema-less, models specify the schema for a document. Each document is made up of keys. Keys are named and type-cast so you know your data is stored in the correct format.

{% highlight ruby %}
class Person
  include MongoMapper::Document

  key :first_name,  String
  key :last_name,   String
  key :age,         Integer
  key :born_at,     Time
  key :active,      Boolean
  key :fav_colors,  Array
end
{% endhighlight %}

Now that we have defined our schema, we can create, update and delete documents.

{% highlight ruby %}
person = Person.create({
  :first_name => 'John',
  :last_name => 'Nunemaker',
  :age => 27,
  :born_at => Time.mktime(1981, 11, 25, 2, 30),
  :active => true,
  :fav_colors => %w(red green blue)
})

person.first_name = 'Johnny'
person.save

person.destroy
# or you could do this to destroy
Person.destroy(person.id)
{% endhighlight %}
