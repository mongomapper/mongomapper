---
layout: documentation
title: Timestamps
---

Declare `timestamps!` in your model to add `created_at` and `updated_at` keys to your document. The values will be automatically set whenever the document is saved.

{% highlight ruby %}
class User
  include MongoMapper::Document

  key :name, String
  timestamps!
end

u = User.create(:name => 'John')
u.created_at # => Sat, 18 Dec 2010 14:52:55 UTC +00:00
u.updated_at # => Sat, 18 Dec 2010 14:52:55 UTC +00:00
u.name = 'Brandon'
u.save
u.updated_at # => Sat, 18 Dec 2010 14:53:07 UTC +00:00
{% endhighlight %}