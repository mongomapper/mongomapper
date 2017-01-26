---
layout: documentation
title: Scopes
---

Scopes allow you to define oft-used queries.

{% highlight ruby %}
class User
  include MongoMapper::Document

  # plain old vanilla scopes with fancy queries
  scope :johns,   where(:name => 'John')

  # plain old vanilla scopes with hashes
  scope :bills, :name => 'Bill'

  # dynamic scopes with parameters
  scope :by_name,  lambda { |name| where(:name => name) }
  scope :by_ages,  lambda { |low, high| where(:age.gte => low, :age.lte => high) }

  # Yep, even plain old methods work as long as they return a query
  def self.by_tag(tag)
    where(:tags => tag)
  end

  # You can even make a method that returns a scope
  def self.twenties; by_ages(20, 29) end

  key :name, String
  key :tags, Array
end

# simple scopes
pp User.johns.first
pp User.bills.first

# scope with arg
pp User.by_name('Frank').first

# scope with two args
pp User.by_ages(20, 29).all

# chaining class methods on scopes
pp User.by_ages(20, 40).by_tag('ruby').all

# scope made using method that returns scope
pp User.twenties.all
{% endhighlight %}
