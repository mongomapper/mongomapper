# encoding: UTF-8
require File.expand_path('../lib/mongo_mapper/version', __FILE__)

Gem::Specification.new do |s|
  s.name               = 'mongo_mapper'
  s.homepage           = 'http://mongomapper.com'
  s.summary            = 'A Ruby Object Mapper for Mongo'
  s.description        = 'MongoMapper is a Object-Document Mapper for Ruby and Rails'
  s.require_path       = 'lib'
  s.license            = 'MIT'
  s.authors            = ['John Nunemaker', 'Chris Heald', 'Scott Taylor']
  s.email              = ['nunemaker@gmail.com', 'cheald@gmail.com', 'scott@railsnewbie.com']
  s.executables        = ['mmconsole']
  s.version            = MongoMapper::Version
  s.platform           = Gem::Platform::RUBY
  s.files              = Dir.glob("{bin,examples,lib,spec}/**/*") + %w[LICENSE UPGRADES README.md]

  s.add_dependency 'mongo',         '~> 2.0'
  s.add_dependency 'plucky',        '~> 0.8.0'

  s.add_dependency 'activesupport', '>= 5.0'
  s.add_dependency 'activemodel',   ">= 5.0"
  s.add_dependency 'activemodel-serializers-xml', "~> 1.0"
end
