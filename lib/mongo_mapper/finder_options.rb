module MongoMapper
  class FinderOptions
    OptionKeys = [:fields, :select, :skip, :offset, :limit, :sort, :order]
    
    attr_reader :model, :options
    
    def initialize(model, options)
      raise ArgumentError, "FinderOptions must be a hash" unless options.is_a?(Hash)
      options.symbolize_keys!
      
      @model, @options, @conditions = model, {}, options.delete(:conditions) || {}
      
      options.each_pair do |key, value|
        if OptionKeys.include?(key)
          @options[key] = value
        else
          @conditions[key] = value
        end
      end
    end
    
    def criteria
      to_mongo_criteria(model, @conditions)
    end
    
    def options
      to_mongo_options(model, @options)
    end
    
    def to_a
      [criteria, options]
    end
    
    private
      def to_mongo_criteria(model, conditions, parent_key=nil)
        criteria = {}
        add_sci_scope(model, criteria)

        conditions.each_pair do |field, value|
          field = field_normalized(field)
          case value
            when Array
              operator_present = field.to_s =~ /^\$/            
              criteria[field] = if operator_present
                                  value
                                else
                                  {'$in' => value}
                                end
            when Hash
              criteria[field] = to_mongo_criteria(model, value, field)
            else            
              criteria[field] = value
          end
        end

        criteria
      end
      
      def field_normalized(field)
        if field.to_s == 'id'
          :_id
        else
          field
        end
      end

      # adds _type single collection inheritance scope for models that need it
      def add_sci_scope(model, criteria)
        if model.single_collection_inherited?
          criteria[:_type] = model.to_s
        end
      end

      def to_mongo_options(model, options)
        options = options.dup
        {
          :fields => to_mongo_fields(options.delete(:fields) || options.delete(:select)),
          :skip   => (options.delete(:skip) || options.delete(:offset) || 0).to_i,
          :limit  => (options.delete(:limit) || 0).to_i,
          :sort   => options.delete(:sort) || to_mongo_sort(options.delete(:order))
        }
      end
      
      def to_mongo_fields(fields)
        return if fields.blank?
      
        if fields.is_a?(String)
          fields.split(',').map { |field| field.strip }
        else
          fields.flatten.compact
        end
      end
    
      def to_mongo_sort(sort)
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