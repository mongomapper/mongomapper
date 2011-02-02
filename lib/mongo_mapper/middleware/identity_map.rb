module MongoMapper
  module Middleware
    class IdentityMap
      def initialize(app)
        @app = app
      end

      def call(env)
        MongoMapper::Plugins::IdentityMap.clear
        @app.call(env)
      ensure
        MongoMapper::Plugins::IdentityMap.clear
      end
    end
  end
end