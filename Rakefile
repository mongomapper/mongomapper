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

desc 'Update contributors'
task :update_contributors do
  git_rank_contributors = File.expand_path('etc/git-rank-contributors', __dir__)
  sh "#{git_rank_contributors} > CONTRIBUTORS && git add CONTRIBUTORS"
end

task update_contributors_and_commit: [:update_contributors] do
  sh "git commit -m 'Updating Contributors'"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => [:spec, :update_contributors_and_commit, :build] do
  sh "git tag v#{MongoMapper::Version}"
  sh "git push origin master"
  sh "git push origin v#{MongoMapper::Version}"
  sh "gem push mongo_mapper-#{MongoMapper::Version}.gem"
end
