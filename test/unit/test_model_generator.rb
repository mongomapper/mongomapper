require 'rails/generators'
require 'rails/generators/mongo_mapper/model/model_generator'

class ModelGeneratorTest < Rails::Generators::TestCase
  tests MongoMapper::Generators::ModelGenerator

  destination File.expand_path('../tmp', File.dirname(__FILE__))

  setup :prepare_destination
  teardown :cleanup_destination_root

  test 'help shows MongoMapper options' do
    content = run_generator ['--help']
    assert_match(/rails generate mongo_mapper:model/, content)
  end

  test 'model are properly created' do
    run_generator ['Color']
    assert_file 'app/models/color.rb', /class Color/
    assert_file 'app/models/color.rb', /include MongoMapper::Document/
  end

  test 'model are properly created with attributes' do
    run_generator ['Color', 'name:string', 'saturation:integer']
    assert_file 'app/models/color.rb', /class Color/
    assert_file 'app/models/color.rb', /include MongoMapper::Document/
    assert_file 'app/models/color.rb', /key :name, String/
    assert_file 'app/models/color.rb', /key :saturation, Integer/
  end

  test 'model are properly created with timestamps option' do
    run_generator ['Color', '--timestamps']
    assert_file 'app/models/color.rb', /class Color/
    assert_file 'app/models/color.rb', /include MongoMapper::Document/
    assert_file 'app/models/color.rb', /timestamps/
  end

  protected

    def cleanup_destination_root
      rm_rf(destination_root)
    end

end
