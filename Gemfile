source :rubygems
gemspec

gem 'rake'
gem 'bson_ext', '~> 1.5'
gem 'SystemTimer',  :platform => :mri_18

group(:development) do
  gem 'ruby-debug',   :platform => :mri_18
  gem 'ruby-debug19', :platform => :mri_19, :require => 'ruby-debug'
  gem 'perftools.rb', :platform => :mri,    :require => 'perftools'
end

group :test do
  gem 'rails',             '~> 3.1.4'
  gem 'tzinfo',            '~> 0.3'
  gem 'json',              '~> 1.6'
  gem 'log_buddy',         '~> 0.6'
  gem 'jnunemaker-matchy', '~> 0.4', :require => 'matchy'
  gem 'shoulda',           '~> 2.11'
  gem 'timecop',           '~> 0.3'
  gem 'mocha',             '~> 0.10'
  gem 'rack-test',         '~> 0.6'
end
