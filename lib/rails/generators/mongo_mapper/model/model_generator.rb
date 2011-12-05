# encoding: utf-8

module MongoMapper
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      desc 'Creates a mongomapper model'
      argument :name, :type => :string
      argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"
      class_option :timestamps, :type => :boolean
      check_class_collision

      def self.source_root
        @source_root ||= File.expand_path("../templates", __FILE__)
      end

      def create_model_file
        template 'model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      end

      hook_for :test_framework
    end
  end
end
