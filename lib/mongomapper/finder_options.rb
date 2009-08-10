module MongoMapper
  class FinderOptions
    attr_reader :options
    
    def self.to_mongo_criteria(conditions, parent_key=nil)
      criteria = {}
      conditions.each_pair do |field, value|
        case value
          when Array
            operator_present = field.to_s =~ /^\$/            
            criteria[field] = if operator_present
                                value
                              else
                                {'$in' => value}
                              end
          when Hash
            criteria[field] = to_mongo_criteria(value, field)
          else            
            criteria[field] = value
        end
      end
      
      criteria
    end
        
    def self.to_mongo_options(options)
      options = options.dup
      {
        :fields => to_mongo_fields(options.delete(:fields) || options.delete(:select)),
        :offset => (options.delete(:offset) || 0).to_i,
        :limit  => (options.delete(:limit) || 0).to_i,
        :sort   => options.delete(:sort) || to_mongo_sort(options.delete(:order))
      }
    end
    
    def initialize(options)
      raise ArgumentError, "FinderOptions must be a hash" unless options.is_a?(Hash)
      @options = options.symbolize_keys
      @conditions = @options.delete(:conditions) || {}
    end
    
    def criteria
      self.class.to_mongo_criteria(@conditions)
    end
    
    def options
      self.class.to_mongo_options(@options)
    end
    
    def to_a
      [criteria, options]
    end
    
    private
      def self.to_mongo_fields(fields)
        return if fields.blank?
      
        if fields.is_a?(String)
          fields.split(',').map { |field| field.strip }
        else
          fields.flatten.compact
        end
      end
    
      def self.to_mongo_sort(sort)
        return if sort.blank?
        pieces = sort.split(',')
        pairs  = pieces.map { |s| to_mongo_sort_piece(s) }
      
        hash = OrderedHash.new
        pairs.each do |pair|
          field, sort_direction = pair
          hash[field] = sort_direction
        end
        hash.symbolize_keys
      end
    
      def self.to_mongo_sort_piece(str)
        field, direction = str.strip.split(' ')
        direction ||= 'ASC'
        direction = direction.upcase == 'ASC' ? 1 : -1
        [field, direction]
      end
  end
end