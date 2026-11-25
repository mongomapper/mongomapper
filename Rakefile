require 'rubygems'
require 'bundler/setup'
require 'rake'
require File.expand_path('../lib/mongo_mapper/version', __FILE__)

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rspec_opts = ['--color']
  end
  task :default => :spec
rescue LoadError
  nil
end

desc 'Builds the gem'
task :build do
  sh "gem build mongo_mapper.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install mongo_mapper-#{MongoMapper::Version}"
end

require File.expand_path('../rakelib/release_helper', __FILE__)

GIT_RANK_CONTRIBUTORS = File.expand_path('etc/git-rank-contributors', __dir__)

desc 'Regenerate CONTRIBUTORS with etc/git-rank-contributors'
task :contributors do
  sh "#{GIT_RANK_CONTRIBUTORS} > CONTRIBUTORS"
end

desc 'Update contributors and stage CONTRIBUTORS'
task update_contributors: [:contributors] do
  sh "git add CONTRIBUTORS"
end

task update_contributors_and_commit: [:update_contributors] do
  sh "git commit -m 'Updating Contributors'"
end

def changelog_section!
  section = ReleaseHelper.changelog_section(File.read('CHANGELOG.md'), MongoMapper::Version)
  section or abort "CHANGELOG.md has no '## #{MongoMapper::Version} - YYYY-MM-DD' heading"
end

desc 'Check CHANGELOG.md and CONTRIBUTORS are ready for release'
task :release_checks do
  changelog_section!
  contributors = `#{GIT_RANK_CONTRIBUTORS}`
  abort 'etc/git-rank-contributors failed' unless $?.success?
  abort 'CONTRIBUTORS is stale; run `rake contributors` and commit it' unless contributors == File.read('CONTRIBUTORS')
  puts "Release checks passed for #{MongoMapper::Version}"
end

# Writes the release post and commits/pushes it to gh-pages from a temporary
# worktree, so the current checkout is untouched. dry_run only prints it.
def website_post(dry_run)
  version = MongoMapper::Version
  section = changelog_section!
  path = ReleaseHelper.post_filename(version, section[:date])
  post = ReleaseHelper.render_post(version, section)

  sh "git fetch origin +refs/heads/gh-pages:refs/remotes/origin/gh-pages"
  exists = system("git cat-file -e origin/gh-pages:#{path} 2>/dev/null")

  if dry_run
    puts "#{path}#{' (already exists on gh-pages)' if exists}:\n\n#{post}"
    return
  end
  abort "#{path} already exists on gh-pages" if exists

  require 'tmpdir'
  Dir.mktmpdir('mongomapper-gh-pages') do |tmp|
    dir = File.join(tmp, 'gh-pages')
    sh "git branch gh-pages origin/gh-pages" unless system('git rev-parse -q --verify refs/heads/gh-pages >/dev/null')
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

desc 'Publish the mongomapper.com release post to gh-pages (DRY_RUN=1 or [dry_run] to only print it)'
task :website_post, [:dry_run] do |_t, args|
  website_post(args[:dry_run] == 'dry_run' || !ENV['DRY_RUN'].to_s.empty?)
end

desc 'Checks, tags version, pushes to remote, pushes gem, then publishes the website post'
task :release => [:release_checks, :spec, :build] do
  sh "git tag v#{MongoMapper::Version}"
  sh "git push origin master"
  sh "git push origin v#{MongoMapper::Version}"
  sh "gem push mongo_mapper-#{MongoMapper::Version}.gem"
  website_post(false) # never a dry run here, even if DRY_RUN is set
end
