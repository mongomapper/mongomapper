module MongoMapper
  class DynamicFinder
    attr_reader :method, :attributes, :finder, :bang, :instantiator

    def initialize(method)
      @method = method
      @finder = :first
      @bang   = false
      match()
    end

    def valid?
      @finder.present?
    end

    protected
      def match        
        case method.to_s
          when /^find_(all_by|by)_([_a-zA-Z]\w*)$/
            @finder = :all if $1 == 'all_by'
            names = $2
          when /^find_by_([_a-zA-Z]\w*)\!$/
            @bang = true
            names = $1
          when /^find_or_(initialize|create)_by_([_a-zA-Z]\w*)$/
            @instantiator = $1 == 'initialize' ? :new : :create
            names = $2
          else
            @finder = nil
        end
        
        @attributes = names && names.split('_and_')
      end
  end
end
