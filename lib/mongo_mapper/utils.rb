module MongoMapper
  module Utils
    def self.get_safe_options(options)
      safe = options[:safe]
      safe = {:w => 1} if safe == true or safe.nil?
      safe = {:w => 0} if safe == false
      safe = {:w => safe} if safe.is_a? Fixnum
      safe
    end
  end
end