require 'rubygems'
require 'rake'
require 'rake/testtask'
require File.expand_path('../lib/mongo_mapper/version', __FILE__)

namespace :test do
  Rake::TestTask.new(:all) do |test|
    test.libs      << 'lib' << 'test'
    test.pattern   = 'test/{functional,unit}/**/test_*.rb'
  end

  desc "Run active model lint test"
  task :am_lint do
    sh 'ruby -Itest -rubygems test/test_active_model_lint.rb'
  end
end

desc 'Runs all tests against ActiveSupport 2 and 3'
task :test do
  Rake::Task['test:all'].invoke
  Rake::Task['test:am_lint'].invoke
end

task :default => :test

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
