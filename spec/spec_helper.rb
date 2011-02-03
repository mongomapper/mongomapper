require 'bundler'
Bundler.require(:default, :development, :test)

Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}
