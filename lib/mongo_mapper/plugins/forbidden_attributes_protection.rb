# encoding: UTF-8
require 'active_model/forbidden_attributes_protection'

module MongoMapper
  module Plugins
    module ForbiddenAttributesProtection
      extend ActiveSupport::Concern
      include ::ActiveModel::ForbiddenAttributesProtection

      def attributes=(attrs={})
        super(sanitize_for_mass_assignment(attrs))
      end

      def update_attributes(attrs={})
        super(sanitize_for_mass_assignment(attrs))
      end

      def update_attributes!(attrs={})
        super(sanitize_for_mass_assignment(attrs))
      end
    end
  end
end
