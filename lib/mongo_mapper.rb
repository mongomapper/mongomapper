require 'date'
require 'time'
require 'pathname'
require 'forwardable'

core_ext = Pathname(__FILE__).dirname.expand_path + 'core_ext'
require core_ext + 'hash_with_indifferent_access'

dir = Pathname(__FILE__).dirname.expand_path + 'mongo_mapper'
require dir + 'document'
require dir + 'key'

module MongoMapper; end