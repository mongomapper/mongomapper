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

          if model.object_id_key?(key)
            case value
              when String
                value = ObjectId.to_mongo(value)
              when Array
                value.map! { |id| ObjectId.to_mongo(id) }
            end
          end

          if symbol_operator?(key)
            key, value = normalized_key(key.field), {"$#{key.operator}" => value}
          end

          criteria[key] = normalized_value(criteria, key, value)
        end

        criteria
      end

      def to_fields(keys)
        return keys if keys.is_a?(Hash)
        return nil  if keys.blank?

        if keys.respond_to?(:flatten, :compact)
          keys.flatten.compact
        else
          keys.split(',').map { |key| key.strip }
        end
      end

      def to_order(key, direction=nil)
        [normalized_key(key).to_s, normalized_direction(direction)]
      end

      def normalized_key(key)
        key.to_s == 'id' ? :_id : key
      end

      # TODO: this is getting heavy enough to move to a class
      def normalized_value(criteria, key, value)
        case value
          when Array, Set
            modifier?(key) ? value.to_a : {'$in' => value.to_a}
          when Hash
            if criteria[key].kind_of?(Hash)
              criteria[key].dup.merge(to_criteria(value, key))
            else
              to_criteria(value, key)
            end
          when Time
            value.utc
          else
            value
        end
      end

      def normalized_direction(direction)
        direction ||= 'asc'
        direction.downcase == 'asc' ? Mongo::ASCENDING : Mongo::DESCENDING
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
