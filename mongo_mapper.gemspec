# encoding: UTF-8
require File.expand_path('../lib/mongo_mapper/version', __FILE__)

Gem::Specification.new do |s|
  s.name               = 'mongo_mapper'
  s.homepage           = 'http://mongomapper.com'
  s.summary            = 'A Ruby Object Mapper for Mongo'
  s.description        = 'MongoMapper is a Object-Document Mapper for Ruby and Rails'
  s.require_path       = 'lib'
  s.license            = 'MIT'
  s.authors            = ['John Nunemaker']
  s.email              = ['nunemaker@gmail.com']
  s.executables        = ['mmconsole']
  s.version            = MongoMapper::Version
  s.platform           = Gem::Platform::RUBY
  s.files              = Dir.glob("{bin,examples,lib,spec}/**/*") + %w[LICENSE UPGRADES README.rdoc]

  s.add_dependency 'activemodel',   ">= 3.0.0"
  s.add_dependency 'activesupport', '>= 3.0'
  s.add_dependency 'plucky',        '~> 0.6.6'
  s.add_dependency 'mongo',         '~> 1.8'
end
