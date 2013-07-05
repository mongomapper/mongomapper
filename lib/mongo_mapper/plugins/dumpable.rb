require 'set'

module MongoMapper
  module Plugins
    module Dumpable
      DUMP_BLACKLIST = Set.new([:@_mm_default_keys, :@_mm_keys, :@errors])

      def marshal_dump
        instance_variables.map(&:to_sym).inject({}) do |h, var|
          h[var] = instance_variable_get(var) unless DUMP_BLACKLIST.include?(var)
          h
        end
      end

      def marshal_load(data)
        data.each do |k, v|
          instance_variable_set(k, v)
        end
      end
    end
  end
end