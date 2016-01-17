# encoding: utf-8

module MongoMapper
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      desc 'Creates a mongomapper model'

      argument :name, :type => :string
      argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"

      check_class_collision

      class_option :timestamps, :type => :boolean
      class_option :parent,     :type => :string, :desc => "The parent class for the generated model"

      def self.source_root
        @source_root ||= File.expand_path("../templates", __FILE__)
      end

      def create_model_file
        template 'model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      end

      hook_for :test_framework

    protected

      def parent_class_name
        options[:parent]
      end

      # Rails 3.0.X compatibility
      unless methods.include?(:module_namespacing)
        def module_namespacing(&block)
          yield if block
        end
      end
    end
  end
end
