require 'rails/generators'
require 'rails/generators/mongo_mapper/config/config_generator'

class ConfigGeneratorTest < Rails::Generators::TestCase
  tests MongoMapper::Generators::ConfigGenerator

  destination File.expand_path('../tmp', File.dirname(__FILE__))

  setup :prepare_destination
  teardown :cleanup_destination_root

  test 'mongo.yml are properly created' do
    run_generator
    assert_file 'config/mongo.yml', /#{File.basename(destination_root)}/
  end

  test 'mongo.yml are properly created with defined database_name' do
    run_generator %w{dummy}
    assert_file 'config/mongo.yml', /dummy/
  end

  protected

    def cleanup_destination_root
      rm_rf(destination_root)
    end

end
