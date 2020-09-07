source 'https://rubygems.org'

gem 'rake'
gem 'multi_json',  '~> 1.2'

gem 'plucky', git: "https://github.com/fcheung/plucky.git", branch: 'mongo-2.x'
gem 'activemodel'
gem 'activemodel-serializers-xml'

if RUBY_PLATFORM != "java"
  gem 'coveralls', :require => false
  gem 'simplecov', :require => false
end
gem 'rest-client'

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

  # puts "RUBY_VERSION: #{RUBY_VERSION}"

  if RUBY_VERSION >= '2.3'
    platforms :mri do
      gem 'byebug'
    end
  end
end
