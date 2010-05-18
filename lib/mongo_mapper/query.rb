module MongoMapper
  class Query
    def initialize(model, options={})
      raise ArgumentError, "Options must be a hash" unless options.is_a?(Hash)
      @model, @options, @conditions = model, {}, {}
      query.update(options)
      add_sci_condition
    end

    private
      def method_missing(method, *args, &block)
        query.send(method, *args, &block)
      end

      def query
        @query ||= Plucky::Query.new(@model.collection).object_ids(@model.object_id_keys)
      end

      def add_sci_condition
        query[:_type] = @model.to_s if @model.single_collection_inherited?
      end
  end
end
