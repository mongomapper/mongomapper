module MongoMapper
  module Middleware
    class IdentityMap
      class Body
        def initialize(target, original)
          @target   = target
          @original = original
        end

        def each(&block)
          @target.each(&block)
        end

        def close
          @target.close if @target.respond_to?(:close)
        ensure
          MongoMapper::Plugins::IdentityMap.enabled = @original
          MongoMapper::Plugins::IdentityMap.clear
        end
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        MongoMapper::Plugins::IdentityMap.clear
        enabled = MongoMapper::Plugins::IdentityMap.enabled
        MongoMapper::Plugins::IdentityMap.enabled = true
        status, headers, body = @app.call(env)
        [status, headers, Body.new(body, enabled)]
      end
    end
  end
end
