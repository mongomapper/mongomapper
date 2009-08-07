module MongoMapper
  class DynamicFinder
    def initialize(model, meth)
      @model = model
      @options = {}
      @options[:method] = meth

      match
    end

    def valid?
      !@options[:finder].nil?
    end

    def run_method(method_args)
      opts = @options

      class << @model; self end.instance_eval do
        define_method(opts[:method]) do |*args|
          find_with_args(args, opts)
        end
      end
      @model.__send__(opts[:method], *method_args)
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
