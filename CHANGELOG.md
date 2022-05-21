<!--
## HEAD
### Enhancements:
### Bug Fixes:
### Doc Fixes:
-->

## Unreleased

* PR-690 jamieorc <jamieorc@gmail.com> Update MongoMapper::Connection.handle_passenger_forking for Mongo 2.x
* PR-692 Masato Ikeda <masato.ikeda@gmail.com>, Scott Taylor <scott@railsnewbie.com> Support Ruby 3.1
* PR-698 thinca <thinca@gmail.com>, Masato Ikeda <masato.ikeda@gmail.com> Fix positional and keyword arguments for ruby 3.x in embedded doc hooks

## 0.15.5 - 2022-02-18
### Enhancements:

* PR-687 Masato Ikeda <masato.ikeda@gmail.com> Support Rails 7.0
* PR-688 Masato Ikeda <masato.ikeda@gmail.com> Delegate hash method to proxy target
* PR-689 Masato Ikeda <masato.ikeda@gmail.com> Add shard keys to upsert query filter

## 0.15.4 - 2021-06-18
### Enhancements:

* PR-680 and PR-685 Masato Ikeda <masato.ikeda@gmail.com> Support Ruby 3.0

## 0.15.3 - 2021-02-11

### Bug Fixes:

* PR-677 Masato Ikeda <masato.ikeda@gmail.com> Reload proxy target for stale nil target on `belongs_to` associations.

  ```ruby
  child = Child.create!(parent: nil)
  child.parent_id = Parent.create!.id
  p child.parent #=> nil
  ```

## 0.15.2 - 2021-01-31

### Enhancements:

* PR-662 Masato Ikeda <masato.ikeda@gmail.com> Add `__FILE__` and `__LINE__` to accessor definitions
* PR-668 ujihisa <ujihisa@users.noreply.github.com> Use GitHub Actions for CI, instead of Travis
* PR-671 ujihisa <ujihisa@users.noreply.github.com> Test against Rails 6.1

### Bug Fixes:

* PR-663 Fumiaki MATSUSHIMA <mtsmfm@gmail.com> Make active_scopes thread safe
* PR-664 Fumiaki MATSUSHIMA <mtsmfm@gmail.com> Fix one embedded proxy to keep the assigned object (don't reassign it)
* PR-665 Fumiaki MATSUSHIMA <mtsmfm@gmail.com> Proxy shouldn't respond to private method
* PR-666 Masato Ikeda <masato.ikeda@gmail.com> Typecast in-array elements before detecting dirty
* PR-667 ujihisa <ujihisa@users.noreply.github.com> Update dirty before callbacks
* PR-670 ujihisa <ujihisa@users.noreply.github.com> Prohibit defining some scope names that overrides existing methods, such as "private"
* PR-672 Fumiaki MATSUSHIMA <mtsmfm@gmail.com> Avoid caching _root_document
* PR-676 Fumiaki MATSUSHIMA <mtsmfm@gmail.com> Reload belongs to association when foreign key is changed


## 0.15.1 - 2020-10-03

### Enhancements:

* PR-649 Chris Heald <cheald@gmail.com> Add StrongParameters plugin. Not included by default.
* PR-615 Kenichi Kamiya <kachick1@gmail.com> Return an Enumerator on #find_each when not given a block
* PR-598 Scott Taylor <scott@railsnewbie.com> Allow incrementing + decrementing using only the field name (example: `obj.increment(:my_counter)`)
* PR-593 Scott Taylor <scott@railsnewbie.com> Add sorting with :ordered => true for has_many :in => :array (Closes #428)
* PR-523 Shevaun Coker <shevaun.coker@gmail.com> Add `assign_attributes` "alias" method for `attributes=`
* PR-259 Hubert <hubert.lepicki@amberbit.com> Add Inverse Many to Many associations.  Example:

    ```ruby
    class List
      include MongoMapper::Document

      key :name, String, required: true
      key :user_ids, Array

      many :users, in: :user_ids
    end

    class User
      include MongoMapper::Document

      key :name, String, required: true

      many :lists, from: :user_ids, as: :user
    end
    ```

* Support ruby 2.7.2


### Bug Fixes:

* PR-640 Seth Jeffery <seth@quipper.com> Fix find! with a one item array to return a one item array object
* PR-628 jamieorc <jamieorc@gmail.com> Corrected a regression on Set keys with typecast
* PR-611 SteffanPerry <sperry1988@gmail.com> Missing yaml requirement was throwing error on rail 4.2.1: "uninitialized constant `MongoMapper::Railtie::YAML` (NameError)"
* Add `attributes` to reserved keys
* Fix infinite regression with duplicate assignment to belongs_to proxy

### Doc Fixes:

* PR-650 Olle Jonsson <olle.jonsson@gmail.com> README: SVG badges
* PR-660 Kenichi Kamiya <kachick1@gmail.com> Fix indent
* PR-617 Kenichi Kamiya <kachick1@gmail.com> Update types to follow Symbol support
* PR-616 Kenichi Kamiya <kachick1@gmail.com> Remove an unused spec


## 0.15.0 - 2020-09-14

* Upgrade to use modern mongo by upgrading to use the mongo 2.0 driver.

  This update means MongoMapper should work with any version of mongo after (2.6+).

  Many thanks to Frederick Cheung <frederick.cheung@gmail.com> for his contribution.

  Note that MyModel.collection now returns a mongo 2.0 driver collection object which does not mirror the shell methods.

  Patches welcome for a compatibility layer!

* Support for ruby 2.4+, rails 5.0+
* Dropping support for all older rubies, older rails.

## 0.14.0 - 2017-01-19
## 0.14.0 RC1 - 2016-03-16

### Enhancements:

* Only partially update objects (using $set and $unset) when updates occur.

  Partial Updates can be turned on or off per class (by default they are off):

    ```ruby
    class Person
      include MongoMapper::Document
      self.partial_updates = true
    end
    ```

  [smtlaissezfaire]

* (Optionally) allow only static (defined) keys, and raise errors for keys that haven't been defined (mimic Mongoid's allow_dynamic_fields = false).

  Turn this on, per model, with:

    ```ruby
    class Person
      include MongoMapper::Document
      self.static_keys = true
    end

    p = Person.new
    p['non_defined_key'] = 'foo' # => MissingKeyError
    ```

  [smtlaissezfaire]

* Add `after_find`, `after_initialize` callbacks [smtlaissezfaire]

### Bug Fixes

* Fix counter caching with polymorphic belongs_to [smtlaissezfaire, bhernez]
* Fix issues with arrays + plucky query. (upgrade to plucky query 0.7.0 - see regressions in scope_spec.rb)

### Internals:

* Don't create accessors for reserved keys (id, class, etc) [cheald]
* Disallow class as a key name [cheald]
* Add ruby 1.8.7 specific gem files to use specific version of i18n <poineau@nationbuilder.com>
* Fixing failing tests for rails 4 <poineau@nationbuilder.com>
* Upgrade to rspec 3.x [smtlaissezfaire, sgnn7]
* Officially Drop support for ruby versions < 2.0.x
* Officially Drop support for rails < 3.2

## 0.13.1 - 2014-11-18

### Enhancements:

* Add counter caching [smtlaissezfaire]
  ```ruby
    belongs_to :user, :counter_cache => true
    belongs_to :user, :counter_cache => :custom_posts_count
  ```

* Add Symbol type [miyucy]
* Add the ability to easily query collection stats:  [sgnn7]

  ```ruby
  MyModel.stats.snake_cased_field
  ```

### Bug Fixes:

* Proxy#send should work with blocks and procs [mgroeneman]
* Support inheriting OneAssociation. [DimaSamodurov]
* write_attribute should return a type casted value [smtlaissezfaire]
* Fix remove_validations_for for AS 4.1 [cpmurphy]
* Fix autosupport loading issue (See rails issue 14664), and add test for ruby 2.1.1 [leifcr]
* Fix syntax error in rescue response declarations for rails < 3.2 was causing MongoMapper::DocumentNotFound exceptions to cause an exception in WebBrick's exception handling in development. [bsoule]

### Internals:

* Lock rest-client to 1.6.7 to ensure installation on 1.8.7
* Added error message: can't mass assign protected attribute. This should be deprecated for proper protected_attributes support down the road.  [ThomasAlxDmy]
* Add a spec to check for extra whitespace in files [rthbound]

## 0.13.0 - 2014-05-2014

### Enhancements:

* Rails 4 support! [cheald]
* Added error message: can't mass assign protected attribute [tdmytryk@fanhattan.com]
* Add Integer#from_mongo. [cheald][#533]
* Normalize IDs passed to #find!, so that it may accept an unsplatted array of IDs, just like #find. [cheald][#468][#469].
* Performance Improvements to: typecasting, identity map, etc. (see a60b04c) [cheald]
* Upgrade safe semantics to be consistent with the new MongoClient safe semantics (:safe => true is now on by default) [cheald]
* Various performance fixes mostly related to avoid extraneous method invocation [cheald]
* Optimization: use key? [jnunemaker]
* Added SSL connection support [daniel.becker@me.com]
* Add automatic id generation when not set (for instance, when calling clone). [wpeterson@brightcove.com]


### Bug Fixes:

* validatior#setup is deprecated in activemodel 4.1 [fcheung]
* Only add the _type key to inherited classes when they have the same collection as their parent. Classes with a different collection name don't need the SCI keys. [cheald]
* remove the _type key when SCI is turned off with set_collection_name. Add specs to cover it. [cheald]
* Key serialization mutates model state when using key Array with option typecast [Oktavilla]
* Be more clear when specifying which version of JRuby mongo_mapper is tested against [tad.hosford@gmail.com]
* Fix db:drop to match everything but system exactly [banyan]
* Fix rescue responses for rails 3.0 and 3.1 [leifrc]
* Use ruby 1.8 syntax for hashes [nigel.ramsay@abletech.co.nz]
* Cast data with loaded from an embedded proxy, as embedded proxies may receive their values from uncast sources. [cheald][#536]
* Permit suppression of accessor methods via the :accessors option to #key. [cheald][#535]
* Guard against failures when the keys are read or written during a hijacked #initialize before we've gotten to run our own #initialize. [pluginaweek][#531]
* When performing Time#to_mongo, round times off to milliseconds and discard microseconds. [cheald][#455]
* Permit the use of #insert and #update in addition to #save, so that we can catch and raise errors in safe mode. [cheald][#398].
* Add critera_hash when single collection inherited. [cheald][#454]
* Fix issues with set_collection_name nullifying SCI on 1.8 [cheald]
* Disable SCI when an inherited model explicitly changes its collection. Closes [cheald][#396]
* Validate key names. Explicitly disallow keys named `id` since they aren't reachable via plucky due to key normalization. Validate key names via regex. [cheald][#399].
* Don't attempt to create a connection when inheriting classes if one does not already exist. [cheald][#460]
* Accept blocks passed to new/build/create/create! on documents and associations. [cheald][#352]
* Compact before setting embedded docs on a many association. [cheald][#288]
* Limit subclass scopes to subclasses. [cheald][#512]
* Update bundler and fix mocha dependency [josevalim]
* Fix Ruby 2.0 breakage caused by behavior changes to #respond_to? [cheald][#473]
* Don't iterate the whole cursor twice when using IdentityMap with #all. Improve performance by avoiding explicit block bindings, extraneous method calls, and extraneous array creation. [cheald]
* Provide a fix for many associations not yielding to each in callbacks. [jnunemaker]
* Support non-ObjectID ids being given to modifiers. [jnunemaker]
* Inherit connection and database name. Subclasses were not getting these before. Only collection name was inherited. [jnunemaker][#420][#424]

### Internals:

* Update travis to test on 2.1.1 [leifcr]
* Do not mutate model values using key with typecast [joel.junstrom@oktavilla.se]
* Setting a key using send should return the new value [tjwp-yesware]
* docs fixes [KristineHines, lucianosousa]
* Lock timecop to 0.6.1 for Ruby 1.8.7 support [cheald]
* Bump plucky requirement to 0.6.5 [cheald]
* Add #dynamic_keys and #defined_keys to let developers distinguish defined schema from derived schema. Use a less clever idiom for 1.8-compatible hash filtering. [cheald]
* Add key aliasing [cheald]
* mongo driver requires that read preference to be type of symbol [foxban@gmail.com]
* changed deleted cursor.next_object method to cursor.next [jamesbowles]
* Use ||= idiom [tn.pablo@gmail.com]
* Update to latest plucky. [nunemaker]
* Added record_timestamps class var to the timestamps plugin [kamil.bednarz@u2i.com]
* reverse_merge! -> reverse_merge [nviennot]
* Some source files were executable [nicolas@viennot.biz]
* Fix legacy mongo class names, that are in deprecation as of 1.8.0. [archSeer]
* move delete and destroy methods to Querying::Decorator [balexand@gmail.com]
* Improvements to key methods (see 942003cca2)[cheald]
* Fix travis suport [wpeterson@brightcove.com]

## 0.12.0 - 2012-09-12

* Identity map is now more opt-in. Middleware turns it on, but it stays off for background jobs and such without explicit intervention.
* Update to latest version of plucky
* Rails 3.2 support
* Support new mongo hosts option format
* A few bug fixes

## 0.11.1 - 2012-03-30

### Enhancements:

* Add ActiveRecord-style #touch to documents and associations
* Add options to atomic modifiers that are passed to the driver
  ```ruby
  Page.increment({:title => "Hello World"}, {:comment_count => 1}, {:upsert => true})
  ```

### Bug Fixes:

* Stop raising error if MongoMapper.database is nil
* Delegate `:distinct`, `:size`, `:reverse`, `:offset`, `:order`, `:empty?`,
  `:filter`, `:find_one`, `:per_page`, `:ignore`, `:only`, and `:to_a` on
  Document to query
* Fix for `EmbeddedDocument#inspect` [#373]
* Ensure milliseconds are preserved with time values [#308]
* Allow MongoMapper.setup to accept a symbol for the environment name

https://github.com/mongomapper/mongomapper/compare/v0.11.0...v0.11.1

## 0.11.0 - 2012-01-26

### Enhancements:

* Adds support for `has_one` polymorphic embedded associations
* Adds namespacing to model generator
* Adds `:context` option to validates_associated

    ```ruby
    many :things
    validates_associated :things, :context => :custom_context
    ```

* Adds ActiveRecord-compatible association reflection
* Adds support for setting mongo connection options in `mongo.yml`

    ```yaml
    production:
      uri: <%= ENV['MONGOHQ_URL'] %>
      options:
        safe: true
    ```

* Adds `#timestamps!` to embedded documents

### Bug Fixes

* `#update_attribute` now ignores attr_accessible and attr_protected
* Fix deprecation warnings in Rails 3.2

https://github.com/jnunemaker/mongomapper/compare/v0.10.1...v0.11.0
