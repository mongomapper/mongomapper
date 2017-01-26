---
layout: documentation
title: Userstamps
---

Declare `userstamps!` in your model to add `creator` and `updater` methods to your document. The values must be set manually like so:

{% highlight ruby %}
class User
  include MongoMapper::Document
  
  key :name, String
end

class Post
  include MongoMapper::Document
  
  key :body, String
  userstamps!
end

u = User.create(:name => 'John')
u2 = User.create(:name => 'J-P')
p = Post.new(:body => 'Lorem ipsum etc..')
p.creator = u
p.updater = u2
p.save
{% endhighlight %}

Note that your users must be in a model with a class named `User` for this to work.

In the above example, `p.creator` would result in the same user as `u` and `p.updater` would result in the same user as `u2`.
