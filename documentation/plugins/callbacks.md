---
layout: documentation
title: Callbacks
---

MongoMapper makes use of the [ActiveModel::Callbacks](http://api.rubyonrails.org/classes/ActiveModel/Callbacks.html), so they are identical to Rails.

The callbacks supported are the same as on ActiveModel, the callbacks provided are:

\* before\_validation
\* after\_validation
\* before\_save
\* after\_save
\* before\_create
\* after\_create
\* before\_update
\* after\_update
\* before\_destroy
\* after\_destroy

For embedded documents you have similar callbacks:

\* before\_validation
\* after\_validation
\* before\_save
\* after\_save
\* before\_create
\* after\_create
\* before\_update
\* after\_update
\* before\_destroy
\* after\_destroy

Example
-------

The callbacks are set on your model like this:

{% highlight ruby %}
class Monkey
  include MongoMapper::Document
  before_save :do_something_before_save

  private
  def do_something_before_save
  end
end
{% endhighlight %}
