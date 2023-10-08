module MongoMapper
  module Plugins
    module StrongParameters
      extend ::ActiveSupport::Concern

      included do
        include ::ActiveModel::ForbiddenAttributesProtection
        class << self
          if ::ActiveSupport.version >= Gem::Version.new("7.1")
            deprecate :attr_protected, :attr_accessible, deprecator: ::MongoMapper.deprecator
          else
            deprecate :attr_protected, :attr_accessible
          end
        end
      end

      def attributes=(attrs = {})
        super sanitize_for_mass_assignment(attrs)
      end

      def update_attributes(attrs = {})
        super sanitize_for_mass_assignment(attrs)
      end

      def update_attributes!(attrs = {})
        super sanitize_for_mass_assignment(attrs)
      end
    end
  end
end
