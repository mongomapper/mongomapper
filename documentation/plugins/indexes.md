---
layout: documentation
title: Indexes
---

Indexing documents is essential for performant queries. Querying on a key that is not indexed results in a scan of each document in a collection. While this may be fine for small collections, it causes extreme slowness in any collection of substance. It is highly recommended that you read Kyle Banker's article on [The Joy of Indexing](http://kylebanker.com/blog/2010/09/21/the-joy-of-mongodb-indexes/) if you have any confusion on the subject.

Mongo creates a default index on the \_id key, but since MongoMapper allows ad hoc queries for more intuitive data access, you need to be aware of how to index those queries as well.

Indexing single key
-------------------

Let's set up an example document on which we will build a few indexes:

{% highlight ruby %}
class User
  include MongoMapper::Document

  key :first_name, String
  key :last_name, String
  key :age, Integer
end
{% endhighlight %}

As we said above, any instance of this class will have \_id key automatically indexed. However, if we wanted to search by first name, Mongo would have to search all User documents for all values that match our query. To speed that up, we can set up an index like so:

{% highlight ruby %}User.ensure_index(:first_name){% endhighlight %}

Now, Mongo will index the **first\_name** key for us and make the queries much faster when dealing with a large collection.

Indexing multiple keys
----------------------

Creating indexes on single keys will improve query performance for those keys only. If you're filtering documents using more than one key, you need to create a compound index. The syntax is similar to that of a single key index with the addition of direction to each key being specified in the compound index. Example is as follows:

{% highlight ruby %}User.ensure_index([[:first_name, 1], [:age, -1]]){% endhighlight %}

This will create an index that looks up the first name in ascending order and age in the descending order.

**Important note**: the order of keys matters in compound indexes. Using the index above, we could query by first\_name or by first\_name and age and both would hit the index. If, however, we queried only by age, a full table scan would occur.

Unique indexes
--------------

Unique indexes guarantee that no documents are inserted whose values for the indexed keys match those of an existing document.

{% highlight ruby %}User.ensure_index [[:email, 1]], :unique => true{% endhighlight %}

If the app attempts to insert a document with a duplicate value after the unique index is set, the insert operation will fail.

**Important note**: Notification of this failure in the form of a raised exception will only occur if the document is saved with :safe =&gt; true. You can read more about the [safe plugin](/documentation/plugins/safe.html) and [updates in the driver](http://blog.mongodb.org/post/2844804263/the-state-of-mongodb-and-ruby) that allow forcing safe-ness.

References
----------

-   [MongoDB indexes](http://www.mongodb.org/display/DOCS/Indexes)
-   [The Joy of Indexing](http://kylebanker.com/blog/2010/09/21/the-joy-of-mongodb-indexes/)
-   [MongoDB data modelling and Rails](http://www.mongodb.org/display/DOCS/MongoDB+Data+Modeling+and+Rails)
-   [MongoDB in Action](http://manning.com/banker/)