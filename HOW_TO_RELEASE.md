How to release:

  * `rake update_contributors_and_commit`
  * version bump in `lib/mongo_mapper/version.rb`
  * run `rake`, afterwards, `git push`
  * finally: `rake release` which will build the gem + push to rubygems.org
  * now update release notes:
    * switch to `gh-pages` branch
    * make a post like:
      ```
        _posts/2021-01-31-release-0-15-2.md

        ---
        title: MongoMapper 0.15.2 Release
        layout: post
        author: Scott Taylor
        ---

        MongoMapper 0.15.2 has been released.

        This is largely a bug fix release from 0.15.1.

        Thanks to the many contributors!

        See the [changelog](https://github.com/mongomapper/mongomapper/blob/master/CHANGELOG.md#0152---2021-01-31) for full details.
      ```
    * push, you should see the changes on mongomapper.com in a minute
