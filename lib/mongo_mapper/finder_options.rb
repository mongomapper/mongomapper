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
  class FinderOptions
    attr_reader :options
    
    # @overload
    #   to_mongo_criteria(conditions)
    #   @param [Hash] conditions field/value pairs
    #
    # @overload
    #   to_mongo_criteria(conditions, parent_key)
    #   @param [Hash] conditions field/value pairs
    #   @param [#to_s] parent_key the name of the key that the current value 
    #     belongs to. This is used internally by this method when recursively 
    #     parsing nested Hash conditions.
    #
    # @return [Hash] conditions compatible with Mongo DB
    def self.to_mongo_criteria(conditions, parent_key=nil)
      criteria = {}
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
            criteria[field] = to_mongo_criteria(value, field)
          else            
            criteria[field] = value
        end
      end
      
      criteria
    end
        
    # @param [Hash] options a set of optoins to convert into a Mongo 
    #   compatible form
    # @option [] :fields
    # @option [] :select may be used instead of <tt>:fields</tt>
    # @option [#to_i] :skip ..., defaults to zero (0)
    # @option [#to_i] :offset may be be used instead of <tt>:skip</tt>
    # @option [#to_i] :limit the number of records to limit your results to, 
    #   defaults to zero (0)
    # @option [] :sort
    # @option [] :order may be used instead of <tt>:order</tt>
    #
    # @return [Hash] converts the provided options into a Mongo compatible 
    #   form. This Hash has four keys: <tt>:fields</tt>, <tt>:skip</tt>, 
    #   <tt>:limit</tt>, <tt>:sort</tt>.
    def self.to_mongo_options(options)
      options = options.dup
      {
        :fields => to_mongo_fields(options.delete(:fields) || options.delete(:select)),
        :skip   => (options.delete(:skip) || options.delete(:offset) || 0).to_i,
        :limit  => (options.delete(:limit) || 0).to_i,
        :sort   => options.delete(:sort) || to_mongo_sort(options.delete(:order))
      }
    end
    
    # @param [#to_s] field target field to normalize
    #
    # @return the normalized field
    def self.field_normalized(field)
      if field.to_s == 'id'
        :_id
      else
        field
      end
    end
    
    OptionKeys = [:fields, :select, :skip, :offset, :limit, :sort, :order]
    
    # Extracts options and conditions from the provided argument and convert 
    # all keys to Symbols. Options are detected via the list of acceptable 
    # option arguments listed in OptionKeys. Conditions may be either 
    # explicitly stated by use of a <tt>:conditions</tt> option, and/or 
    # automatically discovered.
    #
    # @param [Hash] options any number of options or conditions
    # @option [String, Array] :fields a list of field names to use for the 
    #   returned documents
    # @option [String, Array] :select equivalent to <tt>:fields</tt>
    # @option [#to_i] :skip when returning found documents, ignore the first 
    #   +n+ records as defined by this paramter
    # @option [#to_i] :offset equivalent to <tt>:skip</tt>
    # @option [Integer] :limit the number of results to maximally return
    # @option [String] :sort a SQL-style ORDER clause
    # @option [String] :order equivalent to <tt>:sort</tt>
    # @option [Hash] :conditions explicit conditions to initialize 
    #   with (optional)
    #
    # @raise ArgumentError when +options+ provided are not a Hash
    #
    # @see OptionKeys for a list of valid options. Note that this is not a 
    #   list of valid *conditions*.
    def initialize(options)
      raise ArgumentError, "FinderOptions must be a hash" unless options.is_a?(Hash)
      
      options = options.symbolize_keys
      @options, @conditions = {}, options.delete(:conditions) || {}
      
      options.each_pair do |key, value|
        if OptionKeys.include?(key)
          @options[key] = value
        else
          @conditions[key] = value
        end
      end
    end
    
    # @return [Hash] Mongo compatible criteria options
    #
    # @see FinderOptions.to_mongo_criteria
    def criteria
      self.class.to_mongo_criteria(@conditions)
    end
    
    # @return [Hash] Mongo compatible options
    #
    # @see FinderOptions.to_mongo_options
    def options
      self.class.to_mongo_options(@options)
    end
    
    # @return [Array<Hash>] Mongo criteria and options enclosed in an Array
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
        pieces.map { |s| to_mongo_sort_piece(s) }
      end
    
      def self.to_mongo_sort_piece(str)
        field, direction = str.strip.split(' ')
        direction ||= 'ASC'
        direction = direction.upcase == 'ASC' ? 1 : -1
        [field, direction]
      end
  end
end
