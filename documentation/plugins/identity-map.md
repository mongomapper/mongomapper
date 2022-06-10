---
layout: documentation
title: Identity Map
---

The identity map plugin in MongoMapper caches the result of each object being loaded from the database on a per-model basis. If there is an attempt to load that object again from the database, it is loaded from the identity map. The identity map is cleared between requests by `MongoMapper::Middleware::IdentityMap`, which is installed by default in Rails apps.

Identity map is not enabled by default in MongoMapper. Turning on the identity map has two effects. First, you never have two instances of the same object in memory. Second, when possible, MongoMapper attempts to reduce the number of queries executed by checking the map before querying the database. Whenever you do simple finds by id, the map is checked first which reduces the n + 1 query problem.

Examples
--------

{% highlight ruby %}class Item
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  key :title, String
  key :parent_id, ObjectId

  belongs_to :parent, :class_name => 'Item'
end

root = Item.create(:title => 'Root') # adds root to IM
child = Item.create(:title => 'Child', :parent => root) # adds child to IM
grand_child = Item.create(:title => 'Grand Child', :parent => child) # adds grand_child to IM

# Queries for all items, loads objects from map instead of creating new objects
items = Item.all
puts items.detect { |i| i._id == root._id }.equal?(root) # true, same object in memory

# No query to the database as root is in memory
puts Item.find(root._id).equal?(root) # true, same object in memory

# Loads root, which is in map, no query to database even though through association
child.parent
{% endhighlight %}

Usage
-----

Add the plugin to each model individually by declaring the plugin:

{% highlight ruby %}class Item
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap
end
{% endhighlight %}

To turn on the plugin for all your models, declare the plugin on Document.

{% highlight ruby %}
MongoMapper::Document.plugin(MongoMapper::Plugins::IdentityMap)
{% endhighlight %}

References
----------

-   [John Nunemaker's article on IdentityMap in MongoMapper](http://railstips.org/blog/archives/2010/02/21/mongomapper-07-identity-map/)
-   [IdentityMap by Martin Fowler](http://www.martinfowler.com/eaaCatalog/identityMap.html)
-   [IdentityMap on Wikipedia](http://en.wikipedia.org/wiki/Identity_map)