module MongoMapper
  # = Important Note
  # This class is private to MongoMapper and should not be considered part of 
  # MongoMapper's public API.
  #
  class FinderOptions
    OptionKeys = [:fields, :select, :skip, :offset, :limit, :sort, :order]

    def self.normalized_field(field)
      field.to_s == 'id' ? :_id : field
    end

    def self.normalized_order_direction(direction)
      direction ||= 'ASC'
      direction.upcase == 'ASC' ? 1 : -1
    end

    def initialize(model, options)
      raise ArgumentError, "Options must be a hash" unless options.is_a?(Hash)
      options = options.symbolize_keys

      @model      = model
      @options    = {}
      @conditions = options.delete(:conditions) || {}

      options.each_pair do |key, value|
        if OptionKeys.include?(key)
          @options[key] = value
        else
          @conditions[key] = value
        end
      end

      add_sci_scope
    end

    def criteria
      to_mongo_criteria(@conditions)
    end

    def options
      fields = @options.delete(:fields) || @options.delete(:select)
      skip   = @options.delete(:skip)   || @options.delete(:offset) || 0
      limit  = @options.delete(:limit)  || 0
      sort   = @options.delete(:sort)   || convert_order_to_sort(@options.delete(:order))

      {:fields => to_mongo_fields(fields), :skip => skip.to_i, :limit => limit.to_i, :sort => sort}
    end

    def to_a
      [criteria, options]
    end

    private
      def to_mongo_criteria(conditions, parent_key=nil)
        criteria = {}

        conditions.each_pair do |field, value|
          field = self.class.normalized_field(field)
          
          if @model.object_id_key?(field) && value.is_a?(String)
            value = Mongo::ObjectID.from_string(value)
          end
          
          if field.is_a?(FinderOperator)
            criteria.update(field.to_criteria(value))
            next
          end
          
          case value
            when Array
              criteria[field] = operator?(field) ? value : {'$in' => value}
            when Hash
              criteria[field] = to_mongo_criteria(value, field)
            when Time
              criteria[field] = value.utc
            else            
              criteria[field] = value
          end
        end

        criteria
      end

      def operator?(field)
        field.to_s =~ /^\$/
      end

      # adds _type single collection inheritance scope for models that need it
      def add_sci_scope
        if @model.single_collection_inherited?
          @conditions[:_type] = @model.to_s
        end
      end

      def to_mongo_fields(fields)
        return if fields.blank?

        if fields.respond_to?(:flatten, :compact)
          fields.flatten.compact
        else
          fields.split(',').map { |field| field.strip }
        end
      end

      def convert_order_to_sort(sort)
        return if sort.blank?
        
        if sort.respond_to?(:all?) && sort.all? { |s| s.respond_to?(:to_order) }
          sort.map { |s| s.to_order }
        elsif sort.respond_to?(:to_order)
          [sort.to_order]
        else
          pieces = sort.split(',')
          pieces.map { |s| to_mongo_sort_piece(s) }
        end
      end

      def to_mongo_sort_piece(str)
        field, direction = str.strip.split(' ')
        direction = FinderOptions.normalized_order_direction(direction)
        [field, direction]
      end
  end
  
  class FinderOperator
    def initialize(field, operator)
      @field, @operator = field, operator
    end
    
    def to_criteria(value)
      {FinderOptions.normalized_field(@field) => {@operator => value}}
    end
  end
  
  class OrderOperator
    def initialize(field, direction)
      @field, @direction = field, direction
    end
    
    def to_order
      [@field.to_s, FinderOptions.normalized_order_direction(@direction)]
    end
  end
end
