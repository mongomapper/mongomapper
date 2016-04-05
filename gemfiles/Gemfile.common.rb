source 'https://rubygems.org'

gem 'rake', "< 11.0"
gem 'multi_json',  '~> 1.2'

if RUBY_PLATFORM != "java"
  gem 'coveralls', :require => false
  gem 'simplecov', :require => false
end
gem 'rest-client', '1.6.7'

platforms :ruby do
  gem 'mongo',     '~> 2.0'
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

  platforms :mri_18 do
    gem 'ruby-debug'
  end

  platforms :mri_19 do
    gem 'debugger'
  end

  platforms :mri_20 do
    gem 'pry'
  end

  platforms :mri_23 do
    gem 'byebug'
  end

end
