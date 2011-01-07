require 'test_helper'
require 'rack/test'

class IdentityMapMiddlewareTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    @app ||= Rack::Builder.new do
      use MongoMapper::Middleware::IdentityMap
      map "/" do
        run lambda {|env| [200, {}, ''] }
      end
      map "/fail" do
        run lambda {|env| raise "FAIL!" }
      end
    end.to_app
  end

  context "with a successful request" do
    should "clear the identity map" do
      MongoMapper::Plugins::IdentityMap.expects(:clear).twice
      get '/'
    end
  end

  context "when the request raises an error" do
    should "clear the identity map" do
      MongoMapper::Plugins::IdentityMap.expects(:clear).twice
      get '/fail' rescue nil
    end
  end


end
