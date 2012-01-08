source :rubygems
gemspec

group :development, :test, :rspec do
  gem 'bson_ext', '~> 1.5'

  gem 'SystemTimer',  :platform => :mri_18
  gem 'ruby-debug',   :platform => :mri_18
  gem 'ruby-debug19', :platform => :mri_19, :require => 'ruby-debug'
  gem 'perftools.rb', :platform => :mri,    :require => 'perftools'

  gem 'rake'
  gem 'tzinfo',            '~> 0.3'
  gem 'json',              '~> 1.6'
  gem 'log_buddy',         '~> 0.6'
  gem 'timecop',           '~> 0.3'
  gem 'rack-test',         '~> 0.6'
  gem 'rails',             '~> 3.0'
end

# FIXME: remove after porting all the specs to rpsec
group :test do
  gem 'jnunemaker-matchy', '~> 0.4.0', :require => 'matchy'
  gem 'shoulda',           '~> 2.11'
  gem 'mocha',             '~> 0.9.8'
end

group :rspec do
  gem 'rspec',             '~> 2.0'
end
