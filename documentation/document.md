---
layout: documentation
title: Document
---

Documents are first class citizens in MongoMapper. Out of the box you can persist them to collections and they can be related to other documents or embedded documents. They also come with all the typical dressings, such as [associations](/documentation/plugins/associations.html), [callbacks](/documentation/plugins/callbacks.html), [serialization](/documentation/plugins/serialization.html), [validations](/documentation/plugins/validations.html), and rich [querying](/documentation/plugins/querying.html).

{% highlight ruby %}
class Article
  include MongoMapper::Document

  key :title,        String
  key :content,      String
  key :published_at, Time
  timestamps!
end
{% endhighlight %}

Custom Connections
------------------

You override the Mongo connection or collection name for a model:

{% highlight ruby %}
class MyModel
  include MongoMapper::Document

  connection Mongo::MongoClient.new('localhost', 27017)
  set_database_name "my_database"
end
{% endhighlight %}
