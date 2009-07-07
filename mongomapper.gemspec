# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mongomapper}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Nunemaker"]
  s.date = %q{2009-07-07}
  s.email = %q{nunemaker@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "History",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/mongomapper.rb",
     "lib/mongomapper/associations.rb",
     "lib/mongomapper/associations/array_proxy.rb",
     "lib/mongomapper/associations/base.rb",
     "lib/mongomapper/associations/belongs_to_proxy.rb",
     "lib/mongomapper/associations/has_many_embedded_proxy.rb",
     "lib/mongomapper/associations/has_many_proxy.rb",
     "lib/mongomapper/associations/polymorphic_belongs_to_proxy.rb",
     "lib/mongomapper/associations/proxy.rb",
     "lib/mongomapper/callbacks.rb",
     "lib/mongomapper/document.rb",
     "lib/mongomapper/embedded_document.rb",
     "lib/mongomapper/finder_options.rb",
     "lib/mongomapper/key.rb",
     "lib/mongomapper/observing.rb",
     "lib/mongomapper/rails_compatibility.rb",
     "lib/mongomapper/save_with_validation.rb",
     "lib/mongomapper/serialization.rb",
     "lib/mongomapper/serializers/json_serializer.rb",
     "lib/mongomapper/validations.rb",
     "mongomapper.gemspec",
     "test/serializers/test_json_serializer.rb",
     "test/test_associations.rb",
     "test/test_callbacks.rb",
     "test/test_document.rb",
     "test/test_embedded_document.rb",
     "test/test_finder_options.rb",
     "test/test_helper.rb",
     "test/test_key.rb",
     "test/test_mongomapper.rb",
     "test/test_observing.rb",
     "test/test_rails_compatibility.rb",
     "test/test_serializations.rb",
     "test/test_validations.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/jnunemaker/mongomapper}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{mongomapper}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Awesome gem for modeling your domain and storing it in mongo}
  s.test_files = [
    "test/serializers/test_json_serializer.rb",
     "test/test_associations.rb",
     "test/test_callbacks.rb",
     "test/test_document.rb",
     "test/test_embedded_document.rb",
     "test/test_finder_options.rb",
     "test/test_helper.rb",
     "test/test_key.rb",
     "test/test_mongomapper.rb",
     "test/test_observing.rb",
     "test/test_rails_compatibility.rb",
     "test/test_serializations.rb",
     "test/test_validations.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_runtime_dependency(%q<mongodb-mongo>, ["= 0.9"])
      s.add_runtime_dependency(%q<jnunemaker-validatable>, ["= 1.7.1"])
      s.add_development_dependency(%q<mocha>, ["= 0.9.4"])
      s.add_development_dependency(%q<jnunemaker-matchy>, ["= 0.4.0"])
    else
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<mongodb-mongo>, ["= 0.9"])
      s.add_dependency(%q<jnunemaker-validatable>, ["= 1.7.1"])
      s.add_dependency(%q<mocha>, ["= 0.9.4"])
      s.add_dependency(%q<jnunemaker-matchy>, ["= 0.4.0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<mongodb-mongo>, ["= 0.9"])
    s.add_dependency(%q<jnunemaker-validatable>, ["= 1.7.1"])
    s.add_dependency(%q<mocha>, ["= 0.9.4"])
    s.add_dependency(%q<jnunemaker-matchy>, ["= 0.4.0"])
  end
end
