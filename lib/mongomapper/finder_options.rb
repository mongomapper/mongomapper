module MongoMapper
  class FinderOptions
    attr_reader :options
    
    def initialize(options)
      raise ArgumentError, "FinderOptions must be a hash" unless options.is_a?(Hash)
      @options = options.symbolize_keys
      @conditions = @options.delete(:conditions) || {}
    end
    
    def criteria
      convert_conditions(@conditions.dup)
    end
    
    def options
      convert_options(@options.dup)
    end
    
    def to_a
      [criteria, options]
    end
    
    private
      def convert_conditions(conditions)
        criteria = {}
        conditions.each_pair do |field, value|
          case value
            when Array
              criteria[field] = {'$in' => value}
            when Hash
              criteria[field] = convert_conditions(value)
            else
              criteria[field] = value
          end
        end
        
        criteria
      end
      
      def convert_options(options)
        {
          :fields => convert_fields(options.delete(:fields) || options.delete(:select)),
          :offset => (options.delete(:offset) || 0).to_i,
          :limit  => (options.delete(:limit) || 0).to_i,
          :sort   => convert_sort(options.delete(:order))
        }
      end
      
      def convert_fields(fields)
        return if fields.blank?
        
        if fields.is_a?(String)
          fields.split(',').map { |field| field.strip }
        else
          fields.flatten.compact
        end
      end
      
      def convert_sort(sort)
        return if sort.blank?
        pieces = sort.split(',')
        pairs  = pieces.map { |s| convert_sort_piece(s) }
        
        hash = OrderedHash.new
        pairs.each do |pair|
          field, sort_direction = pair
          hash[field] = sort_direction
        end
        hash.symbolize_keys
      end
      
      def convert_sort_piece(str)
        field, direction = str.strip.split(' ')
        direction ||= 'ASC'
        direction = direction.upcase == 'ASC' ? 1 : -1
        [field, direction]
      end
  end
end