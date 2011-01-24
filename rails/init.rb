# See http://groups.google.com/group/mongomapper/browse_thread/thread/68f62e8eda43b43a/4841dba76938290c
#
# to_prepare is called before each request in development mode and the first request in production.
Rails.configuration.to_prepare do
  if !Rails.configuration.cache_classes
    # Rails reloading was making descendants fill up and leak memory, these make sure they get cleared
    MongoMapper::Document.descendants.each {|m| m.descendants.clear if m.respond_to?(:descendants) }
    MongoMapper::Document.descendants.clear
    MongoMapper::EmbeddedDocument.descendants.each {|m| m.descendants.clear if m.respond_to?(:descendants) }
    MongoMapper::EmbeddedDocument.descendants.clear
    MongoMapper::Plugins::IdentityMap.models.clear
  end
end

config.middleware.use 'MongoMapper::Middleware::IdentityMap'