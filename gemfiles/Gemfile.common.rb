source 'https://rubygems.org'

gem 'rake'
gem 'multi_json', '~> 1.2'
gem 'plucky', git: "https://github.com/mongomapper/plucky.git", branch: 'v0.8.0'
# gem 'plucky', '~ 0.8.0'
# gem 'activemodel'
# gem 'activemodel-serializers-xml'
# platforms :ruby do
#   gem 'mongo',     '~> 2.0'
# end

if RUBY_PLATFORM != "java"
  gem 'coveralls', :require => false
  gem 'simplecov', :require => false
end

platforms :rbx do
  gem "rubysl"
end

group :test do
  gem 'test-unit',      '~> 3.0'
  gem 'rspec',          '~> 3.4.0'
  gem 'timecop',        '= 0.6.1'
  gem 'rack-test',      '~> 0.5'
  gem 'generator_spec', '~> 0.9'

  if RUBY_ENGINE == "ruby" && RUBY_VERSION >= '2.3'
    platforms :mri do
      gem 'byebug'
    end
  end
end
