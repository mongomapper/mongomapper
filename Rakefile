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

require File.expand_path('../rakelib/release_runner', __FILE__)

desc 'Regenerate CONTRIBUTORS with etc/git-rank-contributors'
task :contributors do
  sh "#{File.expand_path('etc/git-rank-contributors', __dir__)} > CONTRIBUTORS"
end

desc 'Update contributors and stage CONTRIBUTORS'
task update_contributors: [:contributors] do
  sh "git add CONTRIBUTORS"
end

task update_contributors_and_commit: [:update_contributors] do
  sh "git commit -m 'Updating Contributors'"
end

def dry_run?
  !ENV['DRY_RUN'].to_s.empty?
end

desc 'Publish the mongomapper.com release post to gh-pages (DRY_RUN=1 to only print it)'
task :website_post do
  ReleaseRunner.website_post(MongoMapper::Version, File.read('CHANGELOG.md'), dry_run?)
end

desc 'Release BUMP=tiny|minor|major (or VERSION=X.Y.Z) end to end: prep PR, CI, merge, tag, gem push, website post (DRY_RUN=1 to preview)'
task :release do
  begin
    kind, value = ReleaseHelper.release_args(ENV['VERSION'], ENV['BUMP'])
  rescue ArgumentError => e
    abort "#{e.message}\n#{ReleaseHelper::RELEASE_USAGE}"
  end
  version = kind == :bump ? ReleaseRunner.version_for_bump(value) : value
  ReleaseRunner.new(version, dry_run?).run
end

namespace :release do
  %w[tiny patch minor major].each do |bump|
    desc "Same as rake release BUMP=#{bump}"
    task bump do
      ENV['BUMP'] = bump
      Rake::Task[:release].invoke
    end
  end
end
