module MongoMapper
  # Controls the parsing and handling of options used by finders.
  #
  # == Important Note
  #
  # This class is private to MongoMapper and should not be considered part of 
  # MongoMapper's public API. Some documentation herein, however, may prove 
  # useful for understanding how MongoMapper handles the parsing of finder 
  # conditions and options.
  #
  # @private
  class FinderOperator
    def initialize(field, operator)
      @field, @operator = field, operator
    end
    
    def to_criteria(value)
      {@field => {@operator => value}}
    end
  end
  
  class FinderOptions
    OptionKeys = [:fields, :select, :skip, :offset, :limit, :sort, :order]

    def initialize(model, options)
      raise ArgumentError, "Options must be a hash" unless options.is_a?(Hash)
      options = options.clone
      options.symbolize_keys!

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
    
    # @return [Hash] Mongo compatible criteria options
    #
    # @see FinderOptions#to_mongo_criteria
    def criteria
      to_mongo_criteria(@conditions)
    end
    
    # @return [Hash] Mongo compatible options
    def options
      options = @options.dup

      fields = options.delete(:fields) || options.delete(:select)
      skip   = options.delete(:skip)   || options.delete(:offset) || 0
      limit  = options.delete(:limit)  || 0
      sort   = options.delete(:sort)   || convert_order_to_sort(options.delete(:order))

      {:fields => to_mongo_fields(fields), :skip => skip.to_i, :limit => limit.to_i, :sort => sort}
    end
    
    # @return [Array<Hash>] Mongo criteria and options enclosed in an Array
    def to_a
      [criteria, options]
    end

    private
      def to_mongo_criteria(conditions, parent_key=nil)
        criteria = {}

        conditions.each_pair do |field, value|
          field = normalized_field(field)
          if field.is_a?(FinderOperator)
            criteria.merge!(field.to_criteria(value))
            next
          end
          case value
            when Array
              operator_present = field.to_s =~ /^\$/
              criteria[field] = operator?(field) ? value : {'$in' => value}
            when Hash
              criteria[field] = to_mongo_criteria(value, field)
            else            
              criteria[field] = value
          end
        end

        criteria
      end

      def operator?(field)
        field.to_s =~ /^\$/
      end

      def normalized_field(field)
        field.to_s == 'id' ? :_id : field
      end

      # adds _type single collection inheritance scope for models that need it
      def add_sci_scope
        if @model.single_collection_inherited?
          @conditions[:_type] = @model.to_s
        end
      end

      def to_mongo_fields(fields)
        return if fields.blank?

        if fields.is_a?(String)
          fields.split(',').map { |field| field.strip }
        else
          fields.flatten.compact
        end
      end

      def convert_order_to_sort(sort)
        return if sort.blank?
        pieces = sort.split(',')
        pieces.map { |s| to_mongo_sort_piece(s) }
      end

      def to_mongo_sort_piece(str)
        field, direction = str.strip.split(' ')
        direction ||= 'ASC'
        direction = direction.upcase == 'ASC' ? 1 : -1
        [field, direction]
      end
  end
end
