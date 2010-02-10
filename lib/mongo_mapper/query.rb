module MongoMapper
  # IMPORTANT
  # This class is private to MongoMapper and should not be considered part of MongoMapper's public API.
  #
  class Query
    OptionKeys = [:fields, :select, :skip, :offset, :limit, :sort, :order]

    attr_reader :model

    def initialize(model, options)
      raise ArgumentError, "Options must be a hash" unless options.is_a?(Hash)
      @model, @options, @conditions, @original_options = model, {}, {}, options
      separate_options_and_conditions
      add_sci_condition
    end

    def criteria
      to_criteria(@conditions)
    end

    def options
      fields = @options[:fields] || @options[:select]
      skip   = @options[:skip]   || @options[:offset] || 0
      limit  = @options[:limit]  || 0
      sort   = @options[:sort]   || normalized_sort(@options[:order])

      {:fields => to_fields(fields), :skip => skip.to_i, :limit => limit.to_i, :sort => sort}
    end

    def to_a
      [criteria, options]
    end

    private
      def separate_options_and_conditions
        @original_options.each_pair do |key, value|
          key = key.respond_to?(:to_sym) ? key.to_sym : key

          if OptionKeys.include?(key)
            @options[key] = value
          elsif key == :conditions
            @conditions.update(value)
          else
            @conditions[key] = value
          end
        end
      end

      # adds _type single collection inheritance scope for models that need it
      def add_sci_condition
        @conditions[:_type] = model.to_s if model.single_collection_inherited?
      end

      def modifier?(field)
        field.to_s =~ /^\$/
      end

      def symbol_operator?(object)
        object.respond_to?(:field, :operator)
      end

      def to_criteria(conditions, parent_key=nil)
        criteria = {}

        conditions.each_pair do |key, value|
          key = normalized_key(key)

          if model.object_id_key?(key) && value.is_a?(String)
            value = Mongo::ObjectID.from_string(value)
          end

          if symbol_operator?(key)
            value = {"$#{key.operator}" => value}
            key = normalized_key(key.field)
          end

          criteria[key] = normalized_value(key, value)
        end

        criteria
      end

      def to_fields(fields)
        return if fields.blank?

        if fields.respond_to?(:flatten, :compact)
          fields.flatten.compact
        else
          fields.split(',').map { |field| field.strip }
        end
      end

      def to_order(field, direction=nil)
        direction ||= 'ASC'
        direction = direction.upcase == 'ASC' ? 1 : -1
        [field.to_s, direction]
      end

      def normalized_key(field)
        field.to_s == 'id' ? :_id : field
      end

      def normalized_value(field, value)
        case value
          when Array
            modifier?(field) ? value : {'$in' => value}
          when Hash
            to_criteria(value, field)
          when Time
            value.utc
          else
            value
        end
      end

      def normalized_sort(sort)
        return if sort.blank?

        if sort.respond_to?(:all?) && sort.all? { |s| symbol_operator?(s) }
          sort.map { |s| to_order(s.field, s.operator) }
        elsif symbol_operator?(sort)
          [to_order(sort.field, sort.operator)]
        else
          sort.split(',').map do |str|
            to_order(*str.strip.split(' '))
          end
        end
      end
  end
end