# How to release MongoMapper

Replace `X.Y.Z` with the new version (e.g. `0.19.0`) and `YYYY-MM-DD` with
today's date. Run all commands from the repository root.

Steps marked **HUMAN** must be done (or approved) by a maintainer. Everything
else can be done by anyone, including an AI agent.

Never put credentials (RubyGems API keys, OTP codes, GitHub tokens) in this
file, in commits, or in command lines that get logged.

## 1. Start from an up-to-date master and make a branch

```sh
git checkout master
git pull --ff-only origin master
git checkout -b prepare-X.Y.Z-release
```

Check: `git status` is clean and `git log -1 origin/master` matches `git log -1`.

## 2. (Optional) Update contributors

```sh
rake update_contributors_and_commit
```

Check: `git log -1` shows the "Updating Contributors" commit (or nothing to
commit if `CONTRIBUTORS` was already up to date).

## 3. Bump the version

Edit `lib/mongo_mapper/version.rb` and set `MongoMapper::Version`:

```ruby
module MongoMapper
  Version = 'X.Y.Z'
end
```

Check: `ruby -r./lib/mongo_mapper/version -e 'puts MongoMapper::Version'`
prints `X.Y.Z`.

## 4. Update CHANGELOG.md

Add a section for the new version above the previous release, in the existing
style. Use only the headings that have entries:

```markdown
## X.Y.Z - YYYY-MM-DD

### Enhancements:

- PR-NNN Name <email> Description

### Bug Fixes:

- PR-NNN Name <email> Description

### Doc Fixes:

- PR-NNN Name <email> Description
```

To find merged PRs since the last release: `git log --merges --oneline vPREVIOUS..HEAD`.

Check: `grep -n '^## X.Y.Z - ' CHANGELOG.md` finds exactly one line.

## 5. Run the tests locally

```sh
rake
```

Check: the run ends with `0 failures`.

## 6. Open a PR

```sh
git add lib/mongo_mapper/version.rb CHANGELOG.md
git commit -m "Prepare X.Y.Z release"
git push origin prepare-X.Y.Z-release
```

Open a PR against `master` titled "Prepare X.Y.Z release".

Check: the PR diff only touches `lib/mongo_mapper/version.rb`,
`CHANGELOG.md` (and `CONTRIBUTORS` if step 2 was done).

## 7. Wait for CI to be green

CI is the GitHub Actions workflow "Ruby" (`.github/workflows/ruby.yml`).

Check: all jobs of the "Ruby" workflow on the PR are green
(e.g. `gh pr checks <PR number>`).

## 8. **HUMAN:** Approve and merge the PR

A maintainer reviews and merges the prep PR into `master`.

Check: the PR shows as merged.

## 9. Update local master

```sh
git checkout master
git pull --ff-only origin master
```

Check: `git status` is clean, and
`ruby -r./lib/mongo_mapper/version -e 'puts MongoMapper::Version'` prints `X.Y.Z`.
Also confirm the "Ruby" workflow is green on `master` for this commit.

## 10. **HUMAN:** Release

This publishes the gem. It requires a RubyGems owner of `mongo_mapper`
(e.g. Scott Taylor) with 2FA enabled; `gem push` will prompt for the OTP code.

```sh
rake release
```

`rake release` runs, in order:

```sh
rake spec                          # tests
gem build mongo_mapper.gemspec     # builds mongo_mapper-X.Y.Z.gem
git tag vX.Y.Z                     # lightweight tag
git push origin master
git push origin vX.Y.Z
gem push mongo_mapper-X.Y.Z.gem    # prompts for RubyGems OTP
```

If `rake release` stops partway (e.g. the OTP was wrong), run the remaining
commands from the list above by hand instead of re-running the whole task
(re-running would fail on `git tag` because the tag already exists).

Check:
- `git ls-remote --tags origin vX.Y.Z` shows the tag.
- `gem list -r mongo_mapper` (or https://rubygems.org/gems/mongo_mapper) shows `X.Y.Z`.

## 11. (Optional) Publish release notes on mongomapper.com

```sh
git checkout gh-pages
git pull --ff-only origin gh-pages
```

Create `_posts/YYYY-MM-DD-release-X-Y-Z.md`, for example
`_posts/2021-01-31-release-0-15-2.md`:

```markdown
---
title: MongoMapper X.Y.Z Release
layout: post
author: Scott Taylor
---

MongoMapper X.Y.Z has been released.

Thanks to the many contributors!

See the [changelog](https://github.com/mongomapper/mongomapper/blob/master/CHANGELOG.md#xyz---yyyy-mm-dd) for full details.
```

The changelog anchor is the heading with dots and spaces removed, e.g.
`## 0.15.2 - 2021-01-31` becomes `#0152---2021-01-31`.

```sh
git add _posts/YYYY-MM-DD-release-X-Y-Z.md
git commit -m "Release X.Y.Z"
git push origin gh-pages
git checkout master
```

Check: within a minute or so the post appears on https://mongomapper.com.
