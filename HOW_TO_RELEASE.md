# How to release MongoMapper

Replace `X.Y.Z` with the new version (e.g. `0.19.0`). Run from the repository
root, on an up-to-date `master` with a clean working tree.

```sh
DRY_RUN=1 rake release VERSION=X.Y.Z   # optional preview: changes nothing
rake release VERSION=X.Y.Z
```

Steps marked **HUMAN** need the maintainer at the keyboard. Publishing the gem
needs a RubyGems owner of `mongo_mapper` (e.g. Scott Taylor) with 2FA, and
`gh` logged in with rights to merge PRs and push tags/`gh-pages`.

Never put credentials (RubyGems API keys, OTP codes, GitHub tokens) in this
file, in commits, or in command lines that get logged.

## What `rake release VERSION=X.Y.Z` does

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
   `GEM_HOST_OTP_CODE=123456 rake release VERSION=X.Y.Z`, which only makes
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

Fix the cause and rerun the same `rake release VERSION=X.Y.Z`. Every step
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
- **Wrong or expired OTP:** rerun; the tag is kept and only `gem push` and
  the later steps run.

## Smaller tasks

For use by hand, e.g. if the main command already did the earlier steps:

```sh
rake contributors                 # regenerate CONTRIBUTORS
DRY_RUN=1 rake website_post       # print the post for the current version
rake website_post                 # publish it to gh-pages
```

These use the version in `lib/mongo_mapper/version.rb` and its
`CHANGELOG.md` section. To reword a published post, edit it on `gh-pages`.
