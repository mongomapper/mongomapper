# frozen_string_literal: true

module MongoMapper
  def self.deprecator # :nodoc:
    @deprecator ||= ActiveSupport::Deprecation.new("1.0", "mongo_mapper")
  end
end
