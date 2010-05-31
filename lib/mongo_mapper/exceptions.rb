module MongoMapper
  # generic MM error
  class MongoMapperError < StandardError; end

  # raised when key expected to exist but not found
  class KeyNotFound < MongoMapperError; end

  # raised when document expected but not found
  class DocumentNotFound < MongoMapperError; end

  # raised when trying to connect using uri with incorrect scheme
  class InvalidScheme < MongoMapperError; end

  # raised when document not valid and using !
  class DocumentNotValid < MongoMapperError
    def initialize(document)
      super("Validation failed: #{document.errors.full_messages.join(", ")}")
    end
  end
end