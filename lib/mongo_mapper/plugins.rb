# encoding: UTF-8
module MongoMapper
  module Plugins
    def plugins
      @plugins ||= []
    end

    def plugin(mod)
      if ActiveSupport::Concern === mod
        include mod
      else
        warn "[DEPRECATED] Plugins must extend ActiveSupport::Concern"
        extend mod::ClassMethods     if mod.const_defined?(:ClassMethods)
        include mod::InstanceMethods if mod.const_defined?(:InstanceMethods)
        mod.configure(self)          if mod.respond_to?(:configure)
      end
      plugins << mod
    end
  end
end
