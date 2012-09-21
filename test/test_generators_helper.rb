require 'rails/generators'
require 'rails/generators/test_case'

require 'rails/generators/mongo_mapper/config/config_generator'
require 'rails/generators/mongo_mapper/model/model_generator'

module TestGeneratorsHelper
  def self.included(base)
    base.class_eval do
      destination File.expand_path('../tmp', File.dirname(__FILE__))

      setup :prepare_destination
      teardown :cleanup_destination_root

      base.tests MongoMapper::Generators.const_get(base.name.sub(/Test$/, ''))
    end
  end

  def cleanup_destination_root
    rm_rf(destination_root)
  end

end
