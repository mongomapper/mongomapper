require 'spec_helper'
require 'rails/generators'
require 'rails/generators/test_case'
require 'rails/generators/mongo_mapper/config/config_generator'

class ConfigGeneratorTest < ::Rails::Generators::TestCase

  destination File.expand_path('../../tmp', File.dirname(__FILE__))
  setup :prepare_destination
  tests MongoMapper::Generators::ConfigGenerator

  test 'mongo.yml are properly created' do
    run_generator
    assert_file 'config/mongo.yml', /#{File.basename(destination_root)}/
  end

  test 'mongo.yml are properly created with defined database_name' do
    run_generator %w{dummy}
    assert_file 'config/mongo.yml', /dummy/
  end

end
