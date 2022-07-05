module MongoMapper
  module Utils
    def self.get_safe_options(options)
      return {} unless options and options.key? :safe
      safe = options[:safe]
      safe = {:w => 1} if safe == true
      safe = {:w => 0} if safe == false
      safe = {:w => safe} if safe.is_a? Integer
      safe
    end

    def self.filter_param(name, raw_value)
      if ActiveSupport.version >= Gem::Version.new("6.0")
        @filter ||= begin
          require "active_support/parameter_filter"
          ActiveSupport::ParameterFilter.new(MongoMapper.filter_attributes)
        end
        @filter.filter_param(name, raw_value)
      else
        raw_value
      end
    end
  end
end
