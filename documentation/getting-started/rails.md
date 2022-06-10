---
layout: documentation
title: Installation in Rails
---

Using MongoMapper with Rails 3 and 4 is easier than ever. Thanks to new features in ActiveSupport, and the new ActiveModel framework (which MongoMapper 0.9+ uses), your app can be up and running on MongoDB in a matter of seconds.

First, if you're generating a new Rails application, it is recommended to leave out the ActiveRecord dependencies (unless you need them of course). From the console, just run:

{% highlight bash %}
rails new my_app --skip-active-record
{% endhighlight %}

But, not everyone is starting fresh. Andy Lindeman has [an eBook about upgrading from Rails 3 to Rails 4](https://github.com/alindeman/upgradingtorails4). If you're not upgrading, but just converting an existing Rails application from ActiveRecord (or another ORM), simply open `config/application.rb` and replace:

{% highlight ruby %}
require 'rails/all'
{% endhighlight %}

With (for Rails 3):

{% highlight ruby %}
# Pick the frameworks you want:
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"
{% endhighlight %}

Or (for Rails 4):

{% highlight ruby %}
# Pick the frameworks you want:
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_model/railtie"
require "action_view/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"
{% endhighlight %}

Next, add MongoMapper to your `Gemfile`, and run `bundle install`:

{% highlight ruby %}
gem 'mongo_mapper'
gem 'bson_ext'
{% endhighlight %}

Now, you're almost ready to go, but you still need some configuration info. Generate `config/mongo.yml` by running:

{% highlight bash %}
bundle exec rails generate mongo_mapper:config
{% endhighlight %}

If you want to configure your application with a MongoDB URI (i.e. on [Heroku](http://heroku.com)), then you can use the following settings for your production environment:

{% highlight yaml %}
production:
 uri: <%= ENV['MONGODB_URI'] %>
{% endhighlight %}

Technically, you can initialize MongoMapper and use it to store data now. However, I like to configure Rails' model generator. Inside of the Application class (`config/application.rb`) I add:

{% highlight ruby %}
config.generators do |g|
  g.orm :mongo_mapper
end
{% endhighlight %}

One other small note, make sure any ActiveRecord related configuration items are commented out or removed like below:

{% highlight ruby %}
# config.active_record.whitelist_attributes = true
{% endhighlight %}

This will allow you to use the `rails generate model` command with MongoMapper.

You're now finished, go forth and create!

Generate a user model with `bundle exec rails g model user name:string`:

{% highlight bash %}
      invoke  mongo_mapper
      create    app/models/user.rb
      invoke    test_unit
      create      test/models/user_test.rb
      create      test/fixtures/users.yml
{% endhighlight %}

Create a user with `bundle exec rails c`:

{% highlight bash %}
Loading development environment (Rails 4.1.1)
irb(main):001:0> user = User.new(name: 'Mongo')
=> #<User _id: BSON::ObjectId('539645eb43ebd927b2000001'), name: "Mongo">
irb(main):002:0> user.valid?
=> true
irb(main):003:0> user.save
=> true
irb(main):004:0> User.all.count
=> 1
{% endhighlight %}