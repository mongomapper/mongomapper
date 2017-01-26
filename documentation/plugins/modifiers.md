---
layout: documentation
title: Modifiers
---

Along with traditional updates (i.e. replacing an entire document), MongoDB supports atomic, in-place updates with [modifier operations](http://www.mongodb.org/display/DOCS/Updating#Updating-ModifierOperations), allowing you to update existing values for a document.

Let's start with a simple Page model:

{% highlight ruby %}
class Page
  include MongoMapper::Document

  key :title,       String
  key :day_count,   Integer, :default => 0
  key :week_count,  Integer, :default => 0
  key :month_count, Integer, :default => 0
  key :tags,        Array
end
{% endhighlight %}

-   [Operations](#operations)
    -   [increment](#increment)
    -   [decrement](#decrement)
    -   [set](#set)
    -   [unset](#unset)
    -   [push](#push)
    -   [push\_all](#push_all)
    -   [add\_to\_set](#add_to_set)
    -   [push\_uniq](#push_uniq)
    -   [pull](#pull)
    -   [pull\_all](#pull_all)
    -   [pop](#pop)
-   [Options](#options)
-   [Notes](#notes)
-   [Related Resources](#related_resources)

Operations
----------

The atomic modifier operations can be performed directly on instances of your MongoMapper class, or on a collection by passing in the ID (s) or criteria of the documents you wish to modify.

### increment

Increment the given keys by the values specified.

{% highlight ruby %}
@page.increment(:day_count => 1, :week_count => 2, :month_count => 3)
Page.increment({:title => 'Home'}, :day_count => 1, :week_count => 2, :month_count => 3)
Page.increment(@page.id, @page2.id, :day_count => 1, :week_count => 2, :month_count => 3)
{% endhighlight %}

### decrement

Decrement the given keys by the values specified.

{% highlight ruby %}
@page.decrement(:day_count => 1, :week_count => 2, :month_count => 3)
Page.decrement({:title => 'Home'}, :day_count => 1, :week_count => 2, :month_count => 3)
Page.decrement(@page.id, @page2.id, :day_count => 1, :week_count => 2, :month_count => 3)
{% endhighlight %}

### set

Set the values for the keys.

{% highlight ruby %}
@page.set(:title => "New Home")
Page.set({:title => 'Home'}, :title => "New Home")
Page.set(@page.id, @page2.id, :title => "New Home")
{% endhighlight %}

### unset

Unset or remove the given keys.

{% highlight ruby %}
@page.unset(:title)
Page.unset({:title => 'Home'}, :title)
Page.unset(@page.id, @page2.id, :title)
{% endhighlight %}

### push

Append **one** value to the array key.

{% highlight ruby %}
@page.push(:tags => 'foo')
Page.push({:title => 'Home'}, :tags => 'foo')
Page.push(@page.id, @page2.id, :tags => 'foo')
{% endhighlight %}

### push\_all

Append **several** values to the array key.

{% highlight ruby %}
@page.push_all(:tags => ['foo','bar'])
Page.push_all({:title => 'Home'}, :tags => ['foo','bar'])
Page.push_all(@page.id, @page2.id, :tags => ['foo','bar'])
{% endhighlight %}

### add\_to\_set, push\_uniq

Append **one unique** value to the array key.

{% highlight ruby %}
@page.add_to_set(:tags => 'foo')
Page.add_to_set({:title => 'Home'}, :tags => 'foo')
Page.add_to_set(@page.id, @page2.id, :tags => 'foo')
{% endhighlight %}

### pull

Remove **one** value from the array key.

{% highlight ruby %}
@page.pull(:tags => 'foo')
Page.pull({:title => 'Home'}, :tags => 'foo')
Page.pull(@page.id, @page2.id, :tags => 'foo')
{% endhighlight %}

### pull\_all

Remove **several** values from the array key.

{% highlight ruby %}
@page.pull_all(:tags => ['foo','bar'])
Page.pull_all({:title => 'Home'}, :tags => ['foo','bar'])
Page.pull_all(@page.id, @page2.id, :tags => ['foo','bar'])
{% endhighlight %}

### pop

Remove the **last element** from the array key.

{% highlight ruby %}
@page.pop(:tags => 1)
Page.pop({:title => 'Home'}, :tags => 1)
Page.pop(@page.id, @page2.id, :tags => 1)
{% endhighlight %}

Note that if you pass **-1**, it will remove the **first element** from the array.

Options
-------

An options hash can be passed as the final argument. These options will be passed to the Ruby driver's [update method](http://api.mongodb.org/ruby/current/Mongo/Collection.html#update-instance_method).

For example, even though a model's [safe](/documentation/plugins/safe.html) setting will not apply to modifier operations, atomic updates can still be safe:

{% highlight ruby %}
@page.increment({:day_count => 1}, :safe => true)
Page.increment({:title => 'Home'}, {:day_count => 1}, :safe => true)
Page.increment(@page.id, @page2.id, {:day_count => 1}, :safe => true)
{% endhighlight %}

Or, to do an upsert:

{% highlight ruby %}
Page.increment({:title => 'Home'}, {:day_count => 1}, :upsert => true)
{% endhighlight %}

Please note that MongoMapper always sets the [`:multi`](http://www.mongodb.org/display/DOCS/Updating#Updating-update%28%29) option to `true`. This cannot be overridden.

Notes
-----

When applying a modifier operation on a variable (local or instance), make sure to reload the variable. MongoMapper does not update the state of the variable unless you explicitly tell it to like so:

{% highlight ruby %}
@page.set(:title => "Something New")
@page.title # => "Something Old"
@page.reload
@page.title # => "Something New"
{% endhighlight %}

Related Resources
-----------------

[MongoDB Modifier Operations Documentation](http://www.mongodb.org/display/DOCS/Updating#Updating-ModifierOperations)
