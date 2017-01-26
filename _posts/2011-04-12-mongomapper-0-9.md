---
title: MongoMapper 0.9 Release
layout: post
author: Brandon Keepers
---

After months of hard work rewriting MongoMappers internals to use ActiveModel, MongoMapper 0.9 is finally here.

This release support Rails 3 only. There may be one or two more 0.8.x maintenance releases for Rails 2, but the future of MongoMapper is focused on Rails 3.

Changelog
---------

-   A whole lot of Rails 3 goodness.
-   `mongo_mapper:config` and `mongo_mapper:model` generators. [Commit](https://github.com/mongomapper/mongomapper/commit/d79ede021a82ee70b81be1a2e6783d430d0444db) and [Commit](https://github.com/mongomapper/mongomapper/commit/eca638524b67dc6521410f85aad20257be956065)
-   XML serialization thanks to ActiveModel. [Commit](https://github.com/mongomapper/mongomapper/commit/28c1d671abf9718c51c67e59dd9dead786d93b42)
-   Added `:typecast` option for array keys. [Commit](https://github.com/mongomapper/mongomapper/commit/7d6f49bbe35e8d908f35f9d92704e549c365e8c2)
-   Deprecated on plugin structure in favor of using ActiveSupport::Concern. [Commit](https://github.com/mongomapper/mongomapper/commit/7c69e08756b2223db171d7562cf87fac44e2a085)
-   Added :autosave option to associations. [Commit](https://github.com/mongomapper/mongomapper/commit/e6bd6d3008b14b2c9d91a20205871ebc0e5520b8) and [Commit](https://github.com/mongomapper/mongomapper/commit/7cf80d8729d8eb5bfc43e4fb1f63469f70a9c2ca)
-   Many, many bug fixes

See the [full change log](https://github.com/mongomapper/mongomapper/compare/v0.8.6...v0.9.0). This release is not a drop in replacement for 0.8, so check out [UPGRADES](https://github.com/mongomapper/mongomapper/blob/master/UPGRADES) for things that have changed.

Credits
-------

Thanks to everyone that contributed to this release. Especially Brian Ryckbost and Chris Gaffney at [Collective Idea](http://collectiveidea.com) for starting the rails3 branch and doing the grunt of the initial work.

Roadmap
-------

The 0.9 series will hopefully be very short-lived, with 1.0 coming soon. But before we can get to 1.0, we have a [handful of issues](https://github.com/mongomapper/mongomapper/issues?milestone=1&state=open) to resolve and a lot of [documentation to write](/documentation/contributing.html). So go [fork the repo](http://github.com/mongomapper/mongomapper) and lend a hand!
