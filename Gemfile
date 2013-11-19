source 'https://rubygems.org'

gem 'rake'
gem 'multi_json',  '~> 1.2'
gem 'coveralls', require: false
gem 'simplecov', require: false

platforms :ruby do
  gem 'mongo',     '~> 1.9'
  gem 'bson_ext',  '~> 1.9'
end

platforms :rbx do
  gem "rubysl"
end

group :test do
  gem 'rspec',          '~> 2.13'
  gem 'timecop',        '= 0.6.1'
  gem 'rack-test',      '~> 0.5'
  gem 'generator_spec', '~> 0.9'
  gem 'rails',          '~> 4.0.1'
end

gemspec
