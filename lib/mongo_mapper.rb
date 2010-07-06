# encoding: UTF-8
# Make sure you have the correct versions of the gems (see gemspec) in your load path.
require 'plucky'
require 'active_support/all'
require 'active_model'

module MongoMapper
  autoload :Connection,             'mongo_mapper/connection'

  autoload :Error,                  'mongo_mapper/exceptions'
  autoload :DocumentNotFound,       'mongo_mapper/exceptions'
  autoload :InvalidScheme,          'mongo_mapper/exceptions'
  autoload :DocumentNotValid,       'mongo_mapper/exceptions'
  autoload :AccessibleOrProtected,  'mongo_mapper/exceptions'

  autoload :Document,               'mongo_mapper/document'
  autoload :EmbeddedDocument,       'mongo_mapper/embedded_document'
  autoload :Plugins,                'mongo_mapper/plugins'
  autoload :Version,                'mongo_mapper/version'

  module Plugins
    autoload :Associations,     'mongo_mapper/plugins/associations'
    autoload :Accessible,       'mongo_mapper/plugins/accessible'
    autoload :Callbacks,        'mongo_mapper/plugins/callbacks'
    autoload :Caching,          'mongo_mapper/plugins/caching'
    autoload :Clone,            'mongo_mapper/plugins/clone'
    autoload :Descendants,      'mongo_mapper/plugins/descendants'
    autoload :Dirty,            'mongo_mapper/plugins/dirty'
    autoload :Document,         'mongo_mapper/plugins/document'
    autoload :DynamicQuerying,  'mongo_mapper/plugins/dynamic_querying'
    autoload :EmbeddedDocument, 'mongo_mapper/plugins/embedded_document'
    autoload :Equality,         'mongo_mapper/plugins/equality'
    autoload :IdentityMap,      'mongo_mapper/plugins/identity_map'
    autoload :Inspect,          'mongo_mapper/plugins/inspect'
    autoload :Indexes,          'mongo_mapper/plugins/indexes'
    autoload :Keys,             'mongo_mapper/plugins/keys'
    autoload :Logger,           'mongo_mapper/plugins/logger'
    autoload :Modifiers,        'mongo_mapper/plugins/modifiers'
    autoload :Pagination,       'mongo_mapper/plugins/pagination'
    autoload :Persistence,      'mongo_mapper/plugins/persistence'
    autoload :Protected,        'mongo_mapper/plugins/protected'
    autoload :Querying,         'mongo_mapper/plugins/querying'
    autoload :Rails,            'mongo_mapper/plugins/rails'
    autoload :Safe,             'mongo_mapper/plugins/safe'
    autoload :Sci,              'mongo_mapper/plugins/sci'
    autoload :Scopes,           'mongo_mapper/plugins/scopes'
    autoload :Serialization,    'mongo_mapper/plugins/serialization'
    autoload :Timestamps,       'mongo_mapper/plugins/timestamps'
    autoload :Userstamps,       'mongo_mapper/plugins/userstamps'
    autoload :Validations,      'mongo_mapper/plugins/validations'

    module Associations
      autoload :Base,                         'mongo_mapper/plugins/associations/base'
      autoload :Collection,                   'mongo_mapper/plugins/associations/collection'
      autoload :EmbeddedCollection,           'mongo_mapper/plugins/associations/embedded_collection'
      autoload :ManyDocumentsProxy,           'mongo_mapper/plugins/associations/many_documents_proxy'
      autoload :BelongsToProxy,               'mongo_mapper/plugins/associations/belongs_to_proxy'
      autoload :BelongsToPolymorphicProxy,    'mongo_mapper/plugins/associations/belongs_to_polymorphic_proxy'
      autoload :ManyPolymorphicProxy,         'mongo_mapper/plugins/associations/many_polymorphic_proxy'
      autoload :ManyEmbeddedProxy,            'mongo_mapper/plugins/associations/many_embedded_proxy'
      autoload :ManyEmbeddedPolymorphicProxy, 'mongo_mapper/plugins/associations/many_embedded_polymorphic_proxy'
      autoload :ManyDocumentsAsProxy,         'mongo_mapper/plugins/associations/many_documents_as_proxy'
      autoload :OneProxy,                     'mongo_mapper/plugins/associations/one_proxy'
      autoload :OneEmbeddedProxy,             'mongo_mapper/plugins/associations/one_embedded_proxy'
      autoload :InArrayProxy,                 'mongo_mapper/plugins/associations/in_array_proxy'
    end
  end

  extend Connection
end

Dir[File.join(File.dirname(__FILE__), 'mongo_mapper', 'extensions', '*.rb')].each do |extension|
  require extension
end

require 'mongo_mapper/support/descendant_appends'

# FIXME: autoload with proxy is failing, need to investigate
require 'mongo_mapper/plugins/associations/proxy'