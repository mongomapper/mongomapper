# MongoMapper

A Ruby Object Mapper for Mongo.

[<img src="https://badge.fury.io/rb/mongo_mapper.svg" alt="RubyGems">](https://rubygems.org/gems/mongo_mapper)

[<img src="https://github.com/mongomapper/mongomapper/workflows/Ruby/badge.svg?branch=master" alt="Build Status" />](https://github.com/mongomapper/mongomapper/actions?query=workflow%3ARuby+branch%3Amaster)

[<img src="https://coveralls.io/repos/mongomapper/mongomapper/badge.svg" alt="Coverage Status" />](https://coveralls.io/r/mongomapper/mongomapper)

## Install

    $ gem install mongo_mapper

## Documentation

http://mongomapper.com/documentation/

http://rdoc.info/github/mongomapper/mongomapper

## Open Commit Policy

Like Rubinius, we're trying out an "open commit policy".

If you've committed one (code) patch that has been accepted and would like to
work some more on the project, send an email to Scott Taylor
<scott@railsnewbie.com> along with your commit sha1.

## Compatibility

MongoMapper is tested against:

* MRI 2.4 - 3.0.1
* JRuby (Versions with 1.9 compatibility)

Additionally, MongoMapper is tested against:

* Rails 5.0 - 5.2
* Rails 6.0 - 6.1

Note, if you are using Ruby 3.0+, you'll need Rails 6.

## Contributing & Development

    $ git clone https://github.com/mongomapper/mongomapper && cd mongomapper
    $ bundle install
    $ bundle exec rake

* Fork the project.
* Make your feature addition or bug fix. All specs should pass.
* Add specs for your changes. This is important so that it doesn't break in a future version.
* Commit, do not mess with Rakefile, version, or history. If you want to have your own version, that is fine but bump version in a commit by itself in another branch so a maintainer can ignore it when your pull request is merged.
* Send a pull request. Bonus points for topic branches.

## How to release

See `HOW_TO_RELEASE.md`

## Problems or Questions?

Hit up the Google group: http://groups.google.com/group/mongomapper

## Copyright

Copyright (c) 2009-2021 MongoMapper. See LICENSE for details.

## Contributors

MongoMapper/Plucky is:

* John Nunemaker
* Chris Heald
* Scott Taylor

But all open source projects are a team effort and could not happen without
everyone who has contributed.  See `CONTRIBUTORS` for the full list.  Thank you!
