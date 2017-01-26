---
layout: documentation
title: Querying
---

-   [Finders](#finders)
    -   [find](#find)
    -   [all](#all)
    -   [last](#last)
    -   [first](#first)
    -   [find\_each](#find_each)
    -   [paginate](#paginate)
-   [Criteria](#criteria)
    -   [where](#where)
    -   [fields](#fields)
    -   [count](#count)
    -   [sort, order](#sort)
    -   [limit](#limit)
    -   [skip, offset](#skip)
-   [Operators](#operators)
-   [Destroying documents](#destroy_documents)
    -   [destroy](#destroy)
    -   [destroy\_all](#destroy_all)
    -   [delete](#delete)
    -   [delete\_all](#delete_all)

Finders
-------

### find

Find one or more documents by their \_id.

{% highlight ruby %}
# works with string representation of object id
Patient.find('4da32870c198a73ca3000001')

# or with actual object id
Patient.find(BSON::ObjectId.from_string('4da32870c198a73ca3000001'))

# also works with array of ids or multiple arguments
Patient.find(['4da32870c198a73ca3000001', '4da32870c198a73ca3000002'])
Patient.find('4da32870c198a73ca3000001', '4da32870c198a73ca3000002')
{% endhighlight %}

### all

Get all of the documents in a query as an array. Works with options or criteria.

{% highlight ruby %}
Patient.all(:last_name => 'Johnson', :order => :last_name.asc)
{% endhighlight %}

### find\_each

Get all of the documents in a query one at a time and pass them to the given block. Works with options or criteria.
{% highlight ruby %}
Patient.find_each(:last_name => "Johnson") do |document|
  # do something with document
end
{% endhighlight %}

### first

Get the first document in a query. Naturally, this makes the most sense when you have also provided a means of [sorting](#sort).

{% highlight ruby %}
Patient.first(:order => :created_at.desc)
Patient.first(:email => 'john@doe.com')
{% endhighlight %}

### last

Get the last document in a query. Naturally, this makes the most sense when you have also provided a means of [sorting](#sort).

{% highlight ruby %}
Patient.last(:order => :created_at.asc)
{% endhighlight %}

### paginate

Paginate the query.

{% highlight ruby %}
Patient.paginate({
  :order    => :created_at.asc,
  :per_page => 25,
  :page     => 3,
})
{% endhighlight %}

Criteria
--------

Mongo has rich support for [dynamic queries](http://www.mongodb.org/display/DOCS/Querying). MongoMapper uses [Plucky](https://github.com/mongomapper/plucky) to construct query proxy objects that only retrieve data from Mongo when needed. This allows a query to be composed of several conditions before being evaluated.

### where

Use `where` to specify your query criteria.

{% highlight ruby %}
patients = Patient.where(:first_name => "John", :last_name => "Johnson")
{% endhighlight %}

### fields

Sometimes you know you are loading objects for a very specific purpose–maybe to show a few fields on the UI. You can limit the number of fields returned with data filled in as follows:

{% highlight ruby %}
query = Patient.where(:last_name => "Johnson").
        fields(:last_name, :gender).all
#=> [#<Patient created_at: nil, updated_at: nil, _id: BSON::ObjectId('4d140b878951a202ae000002'), gender: "M", last_name: "Johnson", first_name: nil>]
{% endhighlight %}

**Note that all the other attributes in your model will be nil (or set to their default value)**. Therefore, if you call a method that makes use of all the attributes–like `to_json`–then keep in mind that the values will be nil, and you will need to emit only those fields:

{% highlight ruby %}
query.to_json(:only => [:last_name, :gender])
#=> "[{\"last_name\":\"Johnson\",\"gender\":\"M\"}]"
{% endhighlight %}

### count

Instead of returning an array of complete documents, you may want to merely check to see how many exist.

{% highlight ruby %}
patients = Patient.where( :last_name.gte => 'A', :last_name.lt => 'B' ).count
#=> 1803
{% endhighlight %}

### sort, order

You can choose to sort the documents by various keys, ascending (default) or descending.

{% highlight ruby %}
Patient.sort(:last_name)

Patient.where(:updated_at.gte => 3.days.ago).sort(:updated_at.desc)
{% endhighlight %}

### limit

You can limit the number of documents returned by the query.

{% highlight ruby %}
patients = Patient.sort(:last_name).limit(10)
{% endhighlight %}

### skip, offset

Skip is used to return a list of documents beyond the number that are requested to be skipped.

{% highlight ruby %}
patients = Patient.sort(:last_name).limit(10).skip(10)
{% endhighlight %}

### Operators

Mongo supports quite a few [conditional operators](http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-ConditionalOperators). You can use these directly in your MongoMapper queries.

{% highlight ruby %}
User.where(:age => {:$gt => 21, :$lt => 30})
{% endhighlight %}

MongoMapper also provides shorthand for most of these operators.

{% highlight ruby %}
User.where(:age.gt => 21)
{% endhighlight %}

See MongoDB's [documentation on conditional operators](http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-ConditionalOperators).

Destroying documents
--------------------

MongoMapper provides 2 methods for destroying/deleting documents and 2 methods for removing/destroying all documents.

### destroy

Destroy a single or multiple document(s) by providing ID (s) or tne instance of a document

{% highlight ruby %}
# Destroy a single user with the given ID
User.destroy("50a210d2f7aa6006d2000001")

# Destroys two user with given ids
User.destroy("50a210d2f7aa6006d2000001", "50a21153f7aa6006d2000002")

# Delete an instance
u = User.create(:name => cow)
u.destroy
{% endhighlight %}

### destroy\_all

Destroy all or multiple documents from given matching criteria
Warning: You can loose all your data if you call this at the wrong time.

{% highlight ruby %}
# Destroy every user in the collection
User.destroy_all

# Destroys user with a given name
User.destroy_all(:name => "George")
{% endhighlight %}

### delete

Delete document(s) from given ID (s) or the delete an instance of a document.
Callbacks are NOT triggered.

Usage is identical to destroy

### delete\_all

Delete multiple or all documents.
Callbacks are NOT triggered.

Usage is identical to destroy\_all

Related Resources
-----------------

[MongoDB Querying Documentation](http://www.mongodb.org/display/DOCS/Querying)
