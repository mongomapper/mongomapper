# encoding: UTF-8
require File.expand_path('../lib/mongo_mapper/version', __FILE__)

Gem::Specification.new do |s|
  s.name               = 'mongo_mapper'
  s.homepage           = 'http://github.com/jnunemaker/mongomapper'
  s.summary            = 'A Ruby Object Mapper for Mongo'
  s.require_path       = 'lib'
  s.default_executable = 'mmconsole'
  s.authors            = ['John Nunemaker']
  s.email              = ['nunemaker@gmail.com']
  s.executables        = ['mmconsole']
  s.version            = MongoMapper::Version
  s.platform           = Gem::Platform::RUBY
  s.files              = Dir.glob("{bin,examples,lib,rails,test}/**/*") + %w[LICENSE UPGRADES README.rdoc]

  s.add_dependency 'activesupport',           '>= 2.3.4'
  s.add_dependency 'jnunemaker-validatable',  '~> 1.8.4'
  s.add_dependency 'plucky',                  '~> 0.3.5'

  s.add_development_dependency 'json'
  s.add_development_dependency 'log_buddy'
  s.add_development_dependency 'jnunemaker-matchy', '~> 0.4.0'
  s.add_development_dependency 'shoulda',           '~> 2.11'
  s.add_development_dependency 'timecop',           '~> 0.3.1'
  s.add_development_dependency 'mocha',             '~> 0.9.8'
end