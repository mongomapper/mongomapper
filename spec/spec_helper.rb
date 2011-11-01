require 'bundler'
Bundler.require(:default, :development, :rspec)

Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}
