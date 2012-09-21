require 'test_helper'
require 'support/generators_helper'

class ConfigGeneratorTest < Rails::Generators::TestCase
  include TestGeneratorsHelper

  test 'mongo.yml are properly created' do
    run_generator
    assert_file 'config/mongo.yml', /#{File.basename(destination_root)}/
  end

  test 'mongo.yml are properly created with defined database_name' do
    run_generator %w{dummy}
    assert_file 'config/mongo.yml', /dummy/
  end

end
