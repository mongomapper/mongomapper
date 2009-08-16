module MongoMapper
  class DynamicFinder
    attr_reader :options

    def initialize(model, method)
      @model = model
      @options = {}
      @options[:method] = method
      match
    end

    def valid?
      @options[:finder].present?
    end

    protected
      def match
        @options[:finder] = :first
        
        case @options[:method].to_s
          when /^find_(all_by|last_by|by)_([_a-zA-Z]\w*)$/
            @options[:finder] = :last if $1 == 'last_by'
            @options[:finder] = :all if $1 == 'all_by'
            names = $2
          when /^find_by_([_a-zA-Z]\w*)\!$/
            @options[:bang] = true
            names = $1
          when /^find_or_(initialize|create)_by_([_a-zA-Z]\w*)$/
            @options[:instantiator] = $1 == 'initialize' ? :new : :create
            names = $2
          else
            @options[:finder] = nil
        end
        
        @options[:attribute_names] = names && names.split('_and_')
      end
  end
end
