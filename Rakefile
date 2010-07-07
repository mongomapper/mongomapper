require 'rubygems'
require 'rake'
require 'rake/testtask'
require File.expand_path('../lib/mongo_mapper/version', __FILE__)

namespace :test do
  Rake::TestTask.new(:all) do |test|
    test.libs      << 'lib' << 'test'
    test.pattern   = 'test/{functional,unit}/**/test_*.rb'
    test.verbose   = true
  end

  desc "Run active model lint test"
  task :am_lint do
    sh 'ruby -Itest -rubygems test/test_active_model_lint.rb'
  end

  #desc "Run tests against Active Support 2"
  #task :as2 do
  #  sh 'ACTIVE_SUPPORT_VERSION="<= 2.3.8" rake test:all'
  #end

  desc "Run tests against Active Support 3"
  task :as3 do
    sh 'ACTIVE_SUPPORT_VERSION=">= 3.0.0.beta3" rake test:all'
  end
end

desc 'Runs all tests against ActiveSupport 2 and 3'
task :test do
  #Rake::Task['test:as2'].invoke
  Rake::Task['test:as3'].invoke
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
