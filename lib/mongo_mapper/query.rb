# encoding: UTF-8
require 'forwardable'
module MongoMapper
  class Query
    extend Forwardable

    attr_reader    :query, :model
    def_delegators :query, :count, :fields?, :simple?, :to_hash, :[], :[]=

    def initialize(model)
      @model = model
      @query = Plucky::Query.new(model.collection).object_ids(model.object_id_keys)
    end

    def initialize_copy(source)
      super
      @query = @query.clone
    end

    def all(opts={})
      query.all(opts).map { |doc| load(doc) }
    end

    def first(opts={})
      load(query.first(opts))
    end

    def last(opts={})
      load(query.last(opts))
    end

    def update(*args)
      query.update(*args)
      self
    end

    def where(*args)
      @query = query.where(*args)
      self
    end

    def fields(*args)
      @query = query.fields(*args)
      self
    end

    def limit(*args)
      @query = query.limit(*args)
      self
    end

    def skip(*args)
      @query = query.skip(*args)
      self
    end

    def sort(*args)
      @query = query.sort(*args)
      self
    end

    def reverse
      @query = query.reverse
      self
    end

    private
      def load(doc)
        model.load(doc)
      end
  end
end