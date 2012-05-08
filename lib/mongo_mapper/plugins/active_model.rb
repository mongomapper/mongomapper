# encoding: UTF-8
module MongoMapper
  module Plugins
    module ActiveModel
      extend ActiveSupport::Concern

      include ::ActiveModel::Naming
      include ::ActiveModel::Conversion
      include ::ActiveModel::Serialization
      include ::ActiveModel::Serializers::Xml
      include ::ActiveModel::Serializers::JSON

      included do
        extend ::ActiveModel::Translation
      end
    end
  end
end