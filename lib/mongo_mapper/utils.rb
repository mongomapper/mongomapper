require "active_support/parameter_filter"

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

    def self.filter
      @filter ||= ActiveSupport::ParameterFilter.new(MongoMapper.filter_attributes)
    end
  end
end
