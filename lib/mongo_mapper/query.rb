# encoding: UTF-8
require 'forwardable'
module MongoMapper
  class Query
    extend Forwardable

    attr_reader    :model
    def_delegators :query, :count, :fields?, :simple?, :to_hash, :[], :[]=

    def initialize(model)
      @model = model
    end

    def all(opts={})
      spawn.update(opts).all.map { |doc| load(doc) }
    end

    def first(opts={})
      load(spawn.update(opts).first)
    end

    def last(opts={})
      load(spawn.update(opts).last)
    end

    def query
      @query ||= Plucky::Query.new(model.collection).object_ids(model.object_id_keys)
    end

    def spawn
      query.clone
    end

    def update(*args)
      query.update(*args)
      self
    end

    def where(*args)
      query.where(*args)
      self
    end

    def fields(*args)
      query.fields(*args)
      self
    end

    def limit(*args)
      query.limit(*args)
      self
    end

    def skip(*args)
      query.skip(*args)
      self
    end

    def sort(*args)
      query.sort(*args)
      self
    end

    def reverse
      query.reverse
      self
    end

    private
      def load(doc)
        model.load(doc)
      end
  end
end