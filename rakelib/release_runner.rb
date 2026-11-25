require 'json'
require 'net/http'
require 'shellwords'
require 'tempfile'
require 'rake'
require File.expand_path('release_helper', __dir__)

# `rake release BUMP=tiny` (or VERSION=X.Y.Z): the whole release, one step after another.
# Each step first checks whether it is already done, so rerunning the same
# command after a failure skips finished work and continues where it stopped.
# With dry_run nothing is changed: commands are printed instead of run (only
# fetches and read-only gh / RubyGems queries really happen).
class ReleaseRunner
  include Rake::FileUtilsExt
  extend Rake::FileUtilsExt

  VERSION_FILE = 'lib/mongo_mapper/version.rb'.freeze
  RELEASE_FILES = [VERSION_FILE, 'CHANGELOG.md', 'CONTRIBUTORS'].freeze

  attr_reader :version, :branch, :tag

  def initialize(version, dry_run)
    @version = version
    @dry_run = dry_run
    @branch = "prepare-#{version}-release"
    @tag = "v#{version}"
  end

  def run
    $stdout.sync = true
    preflight
    if prep_merged?
      step "Prep PR: #{version} is already on origin/master, skipping prepare/PR"
      sync_master
    else
      prepare
      review_changelog
      open_and_merge_pr
    end
    publish_gem
    step 'Website post'
    self.class.website_post(version, @changelog || File.read('CHANGELOG.md'), @dry_run)
    verify
  end

  # 1. Preflight
  def preflight
    step "Preflight for #{tag}#{' (DRY RUN: nothing will be changed)' if @dry_run}"
    fetch
    current = current_branch
    check(current == 'master' || current == branch, "on master or #{branch} (currently #{current})")

    dirty = `git status --porcelain`.lines.map { |l| l[3..-1].strip }
    resumable = current == branch && (dirty - RELEASE_FILES).empty?
    check(dirty.empty? || resumable, "working tree is clean (#{dirty.join(', ')})")

    if current == 'master'
      up_to_date = rev('HEAD') == rev('origin/master') || (ancestor?('HEAD', 'origin/master') && prep_merged?)
      check(up_to_date, 'master is up to date with origin/master (try git pull --ff-only)')
    else
      check(not_behind?(branch), "#{branch} is not behind origin/#{branch}")
    end

    check(system('gh auth status >/dev/null 2>&1'), 'gh is installed and authenticated (gh auth status)')

    shas = [rev("refs/tags/#{tag}"), remote_tag_sha].compact.uniq
    if shas.size > 1
      check(false, "local and origin #{tag} point at the same commit")
    elsif shas.any?
      check(file_at(shas.first, VERSION_FILE).include?("'#{version}'"),
            "existing tag #{tag} points at a #{version} commit (will skip tagging)")
    else
      check(true, "tag #{tag} does not exist yet")
    end
  end

  # 2. Version, CHANGELOG draft, CONTRIBUTORS on the prep branch
  def prepare
    step "Prepare #{branch}"
    unless current_branch == branch
      exec_cmd(branch_exists? ? "git checkout #{branch}" : "git checkout -b #{branch}")
      check(not_behind?(branch), "#{branch} is not behind origin/#{branch}") unless @dry_run
    end

    source = File.read(VERSION_FILE)
    if source.include?("'#{version}'")
      skip "#{VERSION_FILE} already says #{version}"
    else
      write(VERSION_FILE, ReleaseHelper.set_version(source, version))
    end

    @changelog = File.read('CHANGELOG.md')
    if ReleaseHelper.changelog_section(@changelog, version)
      skip "CHANGELOG.md already has a #{version} heading"
    else
      @changelog = ReleaseHelper.insert_changelog_section(@changelog, draft_changelog)
      write('CHANGELOG.md', @changelog)
    end

    if @dry_run
      puts '[dry run] rake contributors'
    else
      Rake::Task[:contributors].invoke
    end
  end

  # 3. The one pause: accept or edit the changelog section
  def review_changelog
    if ReleaseHelper.changelog_section(file_at("origin/#{branch}", 'CHANGELOG.md'), version)
      skip 'changelog was already reviewed and pushed'
      return
    end

    step "HUMAN: review the #{version} changelog"
    puts ReleaseHelper.changelog_section(@changelog, version)[:text]
    if @dry_run
      puts "[dry run] would ask: Enter to accept, 'e' to edit CHANGELOG.md in #{editor}"
      return
    end
    abort 'Need an interactive terminal to review the changelog.' unless $stdin.tty?

    loop do
      print "Enter to accept, 'e' to edit in #{editor}, 'q' to stop: "
      case $stdin.gets.to_s.strip.downcase
      when '' then return
      when 'q' then abort "Stopped. Rerun `rake release VERSION=#{version}` to continue."
      when 'e'
        system("#{editor} CHANGELOG.md")
        @changelog = File.read('CHANGELOG.md')
        section = ReleaseHelper.changelog_section(@changelog, version)
        return puts("\nUsing:\n\n#{section[:text]}") if section

        puts "CHANGELOG.md has no '## #{version} - YYYY-MM-DD' heading any more."
      end
    end
  end

  # 4. Commit, push, PR, wait for CI, merge
  def open_and_merge_pr
    step 'Prep PR'
    exec_cmd "git add #{RELEASE_FILES.join(' ')}"
    if @dry_run || !system('git diff --cached --quiet')
      exec_cmd "git commit -m 'Prepare #{version} release'"
    else
      skip 'nothing new to commit'
    end

    if !@dry_run && rev("origin/#{branch}") == rev('HEAD')
      skip "origin/#{branch} is up to date"
    else
      exec_cmd "git push -u origin #{branch}"
    end

    pr = find_pr
    abort "PR ##{pr['number']} for #{branch} was closed without merging." if pr && pr['state'] == 'CLOSED'
    if pr.nil?
      create = "gh pr create --base master --head #{branch} --title 'Prepare #{version} release' --body-file"
      return puts("[dry run] #{create} <changelog section>\n[dry run] then wait for CI, merge, and pull master") if @dry_run

      Tempfile.create('pr-body') do |f|
        f.write("#{ReleaseHelper.changelog_section(@changelog, version)[:text]}\nOpened by `rake release VERSION=#{version}`.\n")
        f.flush
        sh "#{create} #{f.path}"
      end
      pr = find_pr
    end

    if pr['state'] == 'MERGED'
      skip "PR ##{pr['number']} is already merged"
    else
      wait_for_ci(pr['number'])
      exec_cmd "gh pr merge #{pr['number']} --merge --match-head-commit #{rev('HEAD')}"
    end
    sync_master
  end

  def wait_for_ci(number)
    puts "Waiting for CI (Ruby workflow) on PR ##{number}..."
    return puts("[dry run] gh pr checks #{number} --watch") if @dry_run

    # Right after a push GitHub may not have registered the checks yet.
    10.times do
      break unless `gh pr checks #{number} 2>&1` =~ /no checks reported/i

      sleep 15
    end
    return if system("gh pr checks #{number} --watch --fail-fast --interval 30")

    abort "CI failed on PR ##{number}; not merging. Fix it on #{branch}, push, and rerun `rake release VERSION=#{version}`."
  end

  def sync_master
    exec_cmd 'git checkout master' unless current_branch == 'master'
    exec_cmd 'git pull --ff-only origin master'
  end

  # 5. Tag, push tag; GitHub Actions (.github/workflows/release.yml) builds
  # the gem and publishes it to RubyGems via trusted publishing.
  def publish_gem
    step 'Publish the gem'
    unless @dry_run || File.read(VERSION_FILE).include?("'#{version}'")
      abort "#{VERSION_FILE} on master is not #{version}"
    end

    if remote_tag_sha
      skip "origin already has #{tag}"
    else
      rev("refs/tags/#{tag}") ? skip("#{tag} already exists locally") : exec_cmd("git tag #{tag}")
      exec_cmd "git push origin #{tag}"
    end

    wait_for_publish
  end

  def wait_for_publish
    return skip("#{version} is already on RubyGems") if published?
    return puts("[dry run] wait for the Release workflow to publish #{version} to RubyGems") if @dry_run

    puts "Waiting for the Release workflow to publish #{version} (gh run list --workflow release.yml)..."
    60.times do
      return puts("    ok: #{version} is on RubyGems") if published?

      sleep 15
    end
    abort "#{version} is not on RubyGems after 15 minutes. Check `gh run list --workflow release.yml`, then rerun `rake release VERSION=#{version}`."
  end

  # 7. Verify
  def verify
    step 'Verify'
    puts "RubyGems: #{version} #{published? ? 'is' : 'is NOT'} published (latest: #{rubygems_latest})"
    sh "git ls-remote --tags origin refs/tags/#{tag}"
    section = ReleaseHelper.changelog_section(@changelog || File.read('CHANGELOG.md'), version)
    puts "Post: #{ReleaseHelper.post_url(version, section[:date])}" if section
  end

  # `rake release BUMP=tiny|minor|major`: the version after the last vX.Y.Z tag
  # (local or on origin; version.rb on origin/master if there are no tags).
  # If version.rb already has that version (checkout, origin/master, or the
  # prep branch) the release is in progress and is resumed, not bumped again.
  def self.version_for_bump(bump)
    sh 'git fetch origin +refs/heads/master:refs/remotes/origin/master'
    show = ->(ref) { ReleaseHelper.version_in(`git show #{ref}:#{VERSION_FILE} 2>/dev/null`) }
    tags = `git tag -l 'v*'`.split +
           `git ls-remote --tags --refs origin 'v*'`.scan(%r{refs/tags/(\S+)}).flatten
    last = ReleaseHelper.latest_version(tags)
    if last
      # A tagged but unfinished release must be finished, not bumped past.
      unless published?(last)
        abort "v#{last} is tagged but not on RubyGems yet. Finish it with `rake release VERSION=#{last}`."
      end
      if `git rev-list --count v#{last}..origin/master 2>/dev/null`.strip == '0'
        abort "Nothing merged since v#{last}. If you are finishing #{last}, use `rake release VERSION=#{last}`."
      end
    end
    last ||= show.call('origin/master') || ReleaseHelper.version_in(File.read(VERSION_FILE))

    target = ReleaseHelper.bump_version(last, bump)
    branch = "prepare-#{target}-release"
    current = [ReleaseHelper.version_in(File.read(VERSION_FILE)), show.call('origin/master'),
               show.call("refs/heads/#{branch}"), show.call("refs/remotes/origin/#{branch}")]
    version, in_progress = ReleaseHelper.next_release(last, bump, current)
    puts "Releasing #{last} -> #{version} (BUMP=#{bump})#{' - already in progress, resuming' if in_progress}"
    version
  rescue ArgumentError => e
    abort e.message
  end

  def self.published?(version)
    url = "https://rubygems.org/api/v2/rubygems/mongo_mapper/versions/#{version}.json"
    Net::HTTP.get_response(URI(url)).is_a?(Net::HTTPSuccess)
  end

  # Writes the release post and commits/pushes it to gh-pages from a temporary
  # worktree, so the current checkout is untouched. Never overwrites a post.
  def self.website_post(version, changelog, dry_run)
    section = ReleaseHelper.changelog_section(changelog, version)
    abort "CHANGELOG.md has no '## #{version} - YYYY-MM-DD' heading" unless section
    path = ReleaseHelper.post_filename(version, section[:date])
    post = ReleaseHelper.render_post(version, section)

    sh 'git fetch origin +refs/heads/gh-pages:refs/remotes/origin/gh-pages'
    if system("git cat-file -e origin/gh-pages:#{path} 2>/dev/null")
      puts "#{path} already exists on gh-pages, skipping"
      return
    end
    return puts("[dry run] would add #{path} to gh-pages:\n\n#{post}") if dry_run

    require 'tmpdir'
    Dir.mktmpdir('mongomapper-gh-pages') do |tmp|
      dir = File.join(tmp, 'gh-pages')
      sh 'git branch gh-pages origin/gh-pages' unless system('git rev-parse -q --verify refs/heads/gh-pages >/dev/null')
      sh "git worktree add #{dir} gh-pages"
      begin
        sh "git -C #{dir} merge --ff-only origin/gh-pages"
        File.write(File.join(dir, path), post)
        sh "git -C #{dir} add #{path}"
        # skip the commit if a previous run committed it but failed to push
        sh "git -C #{dir} diff --cached --quiet || git -C #{dir} commit -m 'Add #{version} release post'"
        sh "git -C #{dir} push origin gh-pages"
      ensure
        sh "git worktree remove --force #{dir}"
      end
    end
  end

  # Draft `## X.Y.Z - today` from PRs merged to master since the previous tag.
  def draft_changelog(from = previous_tag, to = 'origin/master', date = Time.now.strftime('%Y-%m-%d'))
    shas = git("rev-list #{from}..#{to}").split
    prs = JSON.parse(`gh pr list --state merged --base master --limit 200 --json number,title,mergeCommit,author`)
    prs = prs.select { |pr| pr['mergeCommit'] && shas.include?(pr['mergeCommit']['oid']) }
    entries = prs.map { |pr| { number: pr['number'], title: pr['title'], author: pr_author(pr) } }
    puts "    note: no merged PRs found in #{from}..#{to}; add entries by hand" if entries.empty?
    ReleaseHelper.draft_changelog_section(version, date, entries)
  end

  def prep_merged?
    file_at('origin/master', VERSION_FILE).include?("'#{version}'") &&
      !ReleaseHelper.changelog_section(file_at('origin/master', 'CHANGELOG.md'), version).nil?
  end

  def published?
    self.class.published?(version)
  end

  private

  def step(title)
    puts "\n==> #{title}"
  end

  def skip(reason)
    puts "    skip: #{reason}"
  end

  # Preflight-style check: abort when false (dry run: report and keep going).
  def check(ok, description)
    if ok
      puts "    ok: #{description}"
    elsif @dry_run
      puts "    WOULD ABORT: #{description}"
    else
      abort "Release stopped, not true: #{description}"
    end
  end

  def exec_cmd(command)
    @dry_run ? puts("[dry run] #{command}") : sh(command)
  end

  def write(path, content)
    @dry_run ? puts("[dry run] update #{path}") : File.write(path, content)
  end

  def git(args)
    `git #{args} 2>/dev/null`.strip
  end

  def rev(ref)
    sha = git("rev-parse -q --verify #{ref}^{commit}")
    sha.empty? ? nil : sha
  end

  def file_at(ref, path)
    git("show #{ref}:#{path}")
  end

  def ancestor?(a, b)
    system("git merge-base --is-ancestor #{a} #{b}")
  end

  # Updates origin/master and origin/<prep branch> (dropping the latter if it
  # is gone from origin), whatever this clone's fetch refspec is.
  def fetch
    refs = ['master']
    refs << branch if system("git ls-remote --exit-code --heads origin #{branch} >/dev/null")
    sh "git fetch origin #{refs.map { |r| "+refs/heads/#{r}:refs/remotes/origin/#{r}" }.join(' ')}"
    sh "git update-ref -d refs/remotes/origin/#{branch}" if refs.size == 1 && rev("origin/#{branch}")
  end

  def current_branch
    git('rev-parse --abbrev-ref HEAD')
  end

  def not_behind?(name)
    remote = rev("origin/#{name}")
    remote.nil? || ancestor?(remote, 'HEAD')
  end

  def branch_exists?
    rev("refs/heads/#{branch}") || rev("origin/#{branch}")
  end

  # Peeled commit sha of the tag on origin, or nil.
  def remote_tag_sha
    git("ls-remote origin refs/tags/#{tag} refs/tags/#{tag}^{}").lines.last.to_s.split.first
  end

  def previous_tag
    git("describe --tags --abbrev=0 --match 'v[0-9]*' --exclude #{tag} origin/master")
  end

  def find_pr
    prs = JSON.parse(`gh pr list --head #{branch} --base master --state all --json number,state`)
    prs.find { |pr| pr['state'] != 'CLOSED' } || prs.first
  end

  # Credit the first human commit author of the PR; fall back to the GitHub user.
  def pr_author(pr)
    sha = pr['mergeCommit']['oid']
    range = rev("#{sha}^2") ? "#{sha}^1..#{sha}^2" : "-1 #{sha}"
    authors = git("log --no-merges --reverse --format='%an <%ae>' #{range}").lines.map(&:strip)
    ReleaseHelper.pick_author(authors) || begin
      user = pr['author'] || {}
      name = user['name'].to_s.empty? ? user['login'] : user['name']
      email = git("log -1 --format=%ae --author=#{Shellwords.escape(name)}")
      "#{name} <#{email.empty? ? "#{user['login']}@users.noreply.github.com" : email}>"
    end
  end

  def rubygems_latest
    JSON.parse(Net::HTTP.get(URI('https://rubygems.org/api/v1/versions/mongo_mapper/latest.json')))['version']
  end

  def editor
    ENV['VISUAL'] || ENV['EDITOR'] || 'vi'
  end
end
