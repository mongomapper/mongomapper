require 'rubygems'
require 'rake'
require 'jeweler'

require File.dirname(__FILE__) + '/lib/mongo_mapper/version'

Jeweler::Tasks.new do |gem|
  gem.name        = "mongo_mapper"
  gem.summary     = %Q{A Ruby Object Mapper for Mongo}
  gem.email       = "nunemaker@gmail.com"
  gem.homepage    = "http://github.com/jnunemaker/mongomapper"
  gem.authors     = ["John Nunemaker"]
  gem.version     = MongoMapper::Version

  gem.add_dependency('activesupport', '>= 2.3.4')
  gem.add_dependency('mongo', '0.20.1')
  gem.add_dependency('jnunemaker-validatable', '1.8.3')

  gem.add_development_dependency('json', '>= 1.2.3')
  gem.add_development_dependency('jnunemaker-matchy', '0.4.0')
  gem.add_development_dependency('shoulda', '2.10.2')
  gem.add_development_dependency('timecop', '0.3.1')
  gem.add_development_dependency('mocha', '0.9.8')
end

Jeweler::GemcutterTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.ruby_opts << '-rubygems'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default  => :test
task :test     => :check_dependencies
