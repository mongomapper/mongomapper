module Docs
  def self.included(base)
    base.let(:document) { Doc() }
  end

  def Doc(name='Class', &block)
    klass = Class.new
    klass.class_eval do
      include MongoMapper::Document
      set_collection_name :test

      if name
        class_eval "def self.name; '#{name}' end"
        class_eval "def self.to_s; '#{name}' end"
      end
    end

    klass.class_eval(&block) if block_given?
    klass.collection.remove
    klass
  end

  def EDoc(name='Class', &block)
    klass = Class.new do
      include MongoMapper::EmbeddedDocument

      if name
        class_eval "def self.name; '#{name}' end"
        class_eval "def self.to_s; '#{name}' end"
      end
    end

    klass.class_eval(&block) if block_given?
    klass
  end
end