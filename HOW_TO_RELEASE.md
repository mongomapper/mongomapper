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

## 2. Bump the version

Edit `lib/mongo_mapper/version.rb` and set `MongoMapper::Version`:

```ruby
module MongoMapper
  Version = 'X.Y.Z'
end
```

Check: `ruby -r./lib/mongo_mapper/version -e 'puts MongoMapper::Version'`
prints `X.Y.Z`.

## 3. Update CHANGELOG.md

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

## 4. Run the tests locally

```sh
rake
```

Check: the run ends with `0 failures`.

## 5. Update contributors

```sh
git add lib/mongo_mapper/version.rb CHANGELOG.md
git commit -m "Prepare X.Y.Z release"
rake update_contributors_and_commit
rake contributors && git diff --exit-code CONTRIBUTORS
```

This is required: `rake release` fails if `CONTRIBUTORS` is stale. The commits
themselves count towards the ranking, so if the last command shows a diff,
run `rake update_contributors_and_commit` again until it shows none.

## 6. Open a PR

```sh
git push origin prepare-X.Y.Z-release
```

Open a PR against `master` titled "Prepare X.Y.Z release".

Check: the PR diff only touches `lib/mongo_mapper/version.rb`,
`CHANGELOG.md` and `CONTRIBUTORS`.

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
rake release_checks                # CHANGELOG has "## X.Y.Z - YYYY-MM-DD"; CONTRIBUTORS is up to date
rake spec                          # tests
gem build mongo_mapper.gemspec     # builds mongo_mapper-X.Y.Z.gem
git tag vX.Y.Z                     # lightweight tag
git push origin master
git push origin vX.Y.Z
gem push mongo_mapper-X.Y.Z.gem    # prompts for RubyGems OTP
rake website_post                  # mongomapper.com release post (step 11)
```

If `rake release_checks` fails, nothing has been tagged or pushed: fix it with
a new PR to `master` and start again from step 9.

If `rake release` stops after the checks (e.g. the OTP was wrong), run the
remaining commands from the list above by hand instead of re-running the whole
task (re-running would fail on `git tag` because the tag already exists).

Check:
- `git ls-remote --tags origin vX.Y.Z` shows the tag.
- `gem list -r mongo_mapper` (or https://rubygems.org/gems/mongo_mapper) shows `X.Y.Z`.

## 11. Release post on mongomapper.com

`rake release` does this after `gem push`. To do it on its own (e.g. `rake
release` stopped earlier), preview it first, then publish:

```sh
DRY_RUN=1 rake website_post        # prints the post, commits/pushes nothing
rake website_post
```

`rake website_post` builds `_posts/YYYY-MM-DD-release-X-Y-Z.md` (date from
the CHANGELOG heading) with a summary paragraph generated from the CHANGELOG
entries, commits it to `gh-pages` in a temporary git worktree (your checkout
is untouched) and runs `git push origin gh-pages`. It refuses to overwrite an
existing post. To reword the summary, edit the file on `gh-pages` afterwards.

The changelog link anchor is the heading with dots removed and spaces turned
into hyphens, e.g. `## 0.18.1 - 2026-11-24` becomes `#0181---2026-11-24`.

Check: within a minute or so the post is live at
`https://mongomapper.com/blog/YYYY/MM/DD/release-X-Y-Z`.
