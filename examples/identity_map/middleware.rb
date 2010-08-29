# To use this, add the following line in environment.rb
# config.middleware.use 'PerRequestIdentityMap'
class PerRequestIdentityMap
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