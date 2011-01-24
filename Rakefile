require 'rubygems'
require 'rake'
require 'rake/testtask'
require File.expand_path('../lib/mongo_mapper/version', __FILE__)

Rake::TestTask.new(:test) do |test|
  test.libs      << 'lib' << 'test'
  test.pattern   = 'test/{functional,unit}/**/test_*.rb'
end

namespace :test do
  Rake::TestTask.new(:lint) do |test|
    test.libs      << 'lib' << 'test'
    test.pattern   = 'test/test_active_model_lint.rb'
  end

  task :all => ['test', 'test:lint']
end

task :default => 'test:all'

desc 'Builds the gem'
task :build do
  sh "gem build mongo_mapper.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install mongo_mapper-#{MongoMapper::Version}"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{MongoMapper::Version}"
  sh "git push origin master"
  sh "git push origin v#{MongoMapper::Version}"
  sh "gem push mongo_mapper-#{MongoMapper::Version}.gem"
end
