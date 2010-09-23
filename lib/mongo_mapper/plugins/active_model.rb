# encoding: UTF-8
module MongoMapper
  module Plugins
    module ActiveModel
      extend ActiveSupport::Concern

      included do
        include ::ActiveModel::Naming
        include ::ActiveModel::Conversion
        include ::ActiveModel::Serialization
        include ::ActiveModel::Serializers::Xml
        include ::ActiveModel::Serializers::JSON
        include ::ActiveSupport::DescendantsTracker

        extend ::ActiveModel::Translation
      end
    end
  end
end