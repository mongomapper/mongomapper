# How to release MongoMapper

Run from the repository root, on an up-to-date `master` with a clean working
tree. Pick how much to bump the version:

```sh
DRY_RUN=1 rake release BUMP=tiny   # optional preview: changes nothing
rake release BUMP=tiny             # bug-fix release
rake release BUMP=minor            # new features
rake release BUMP=major            # breaking changes
```

`BUMP` counts from the last released version (the highest `vX.Y.Z` tag;
`lib/mongo_mapper/version.rb` if there are no tags). From 0.18.1:

| Command | Releases |
| --- | --- |
| `rake release BUMP=tiny` (or `BUMP=patch`) | 0.18.2 |
| `rake release BUMP=minor` | 0.19.0 |
| `rake release BUMP=major` | 1.0.0 |

The first line of output shows the choice, e.g.
`Releasing 0.18.1 -> 0.18.2 (BUMP=tiny)`. `rake release:tiny`,
`rake release:minor` and `rake release:major` are shorthands for the same.

To pick the version yourself, use `rake release VERSION=X.Y.Z` instead
(not together with `BUMP`). Below, `X.Y.Z` means the version being released.

Steps marked **HUMAN** need the maintainer at the keyboard. Publishing the gem
needs a RubyGems owner of `mongo_mapper` (e.g. Scott Taylor) with 2FA, and
`gh` logged in with rights to merge PRs and push tags/`gh-pages`.

Never put credentials (RubyGems API keys, OTP codes, GitHub tokens) in this
file, in commits, or in command lines that get logged.

## What `rake release BUMP=tiny` does

0. **Pick the version** (`BUMP` only) and print it. If `version.rb` already
   has the bumped version (in your checkout, on `origin/master`, or on the
   prep branch), that release is already in progress, so it continues with
   that version and does not bump again. It stops and asks for `VERSION=...`
   if `version.rb` says anything else. It also stops if the last tag is not
   on RubyGems yet, or if nothing was merged since the last tag.
1. **Preflight.** Fails unless: the working tree is clean; you are on `master`
   (or on `prepare-X.Y.Z-release` when resuming); after `git fetch`, the branch
   is up to date with origin; `gh auth status` succeeds; tag `vX.Y.Z` does
   not exist yet (if an earlier run created it for this version, it is kept
   and tagging is skipped).
2. **Prepare** on branch `prepare-X.Y.Z-release`: set `MongoMapper::Version`
   in `lib/mongo_mapper/version.rb`, draft a `## X.Y.Z - YYYY-MM-DD` section
   in `CHANGELOG.md` from the PRs merged since the previous tag (one
   `- PR-NNN Name <email> Description` line each, grouped by title into
   Enhancements / Bug Fixes / Doc Fixes), and run `rake contributors`.
3. **HUMAN: review the changelog.** The draft is printed once. Press Enter to
   accept it, or `e` to edit `CHANGELOG.md` in `$VISUAL`/`$EDITOR` (default
   `vi`); the saved text is used. `q` stops (rerun to continue). The draft
   is a starting point: fix titles, regroup, credit the right email, drop
   PRs that don't belong.
4. **Prep PR:** commit `Prepare X.Y.Z release`, push the branch, open a PR
   against `master`, wait for CI (`gh pr checks --watch`, the "Ruby"
   workflow), and merge it (merge commit, pinned to the pushed head) only if
   every check passes. Then `git checkout master && git pull --ff-only`.
5. **Publish:** `gem build mongo_mapper.gemspec`, `git tag vX.Y.Z`,
   `git push origin vX.Y.Z`, then `gem push mongo_mapper-X.Y.Z.gem`.
   **HUMAN:** `gem push` asks for your RubyGems OTP; or run with
   `GEM_HOST_OTP_CODE=123456 rake release BUMP=tiny`, which only makes
   sense right before the push is reached, because codes expire.
6. **Website post:** adds `_posts/YYYY-MM-DD-release-X-Y-Z.md` to `gh-pages`
   from a temporary worktree (your checkout is untouched) and pushes it. It
   never overwrites an existing post.
7. **Verify:** prints the RubyGems status, `git ls-remote --tags origin
   vX.Y.Z`, and the post URL
   `https://mongomapper.com/blog/YYYY/MM/DD/release-X-Y-Z`.

`DRY_RUN=1` runs the same sequence, but only fetches and makes read-only
`gh`/RubyGems queries. It prints the changelog draft, the post, and every
command it would run. Failed preflight checks are reported as
`WOULD ABORT` instead of stopping.

## If it stops partway

Fix the cause and rerun the same command (`rake release BUMP=tiny`, or
`rake release VERSION=X.Y.Z`; either works while `version.rb` has the new
version and it is not tagged yet). Every step
first checks whether it is already done and skips it: version already set,
changelog heading present, nothing to commit, branch already pushed, PR
already open or merged, tag already local or on origin, version already on
RubyGems, post already on `gh-pages`. The changelog pause is skipped once
the section is on `origin/prepare-X.Y.Z-release`.

Typical cases:

- **CI failed:** nothing was merged. Push a fix to `prepare-X.Y.Z-release`
  and rerun from that branch.
- **Merge refused** (e.g. the PR needs an approval): get it approved, then
  rerun.
- **Wrong or expired OTP:** rerun with `VERSION=X.Y.Z` (the tag now exists,
  so `BUMP` stops and tells you this); the tag is kept and only `gem push`
  and the later steps run.
- **Website post failed after `gem push`:** rerun with `VERSION=X.Y.Z`, or
  just `rake website_post`. Don't use `BUMP` here: the release is already on
  RubyGems, so `BUMP` would start the next one (it stops only if nothing was
  merged since the tag).

## Smaller tasks

For use by hand, e.g. if the main command already did the earlier steps:

```sh
rake contributors                 # regenerate CONTRIBUTORS
DRY_RUN=1 rake website_post       # print the post for the current version
rake website_post                 # publish it to gh-pages
```

These use the version in `lib/mongo_mapper/version.rb` and its
`CHANGELOG.md` section. To reword a published post, edit it on `gh-pages`.
