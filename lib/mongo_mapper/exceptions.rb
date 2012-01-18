# encoding: UTF-8
module MongoMapper
  # generic MM error
  class Error < StandardError; end

  # raised when document expected but not found
  class DocumentNotFound < Error; end

  # raised when trying to connect using uri with incorrect scheme
  class InvalidScheme < Error; end

  # raised when trying to do something not supported, mostly for edocs
  class NotSupported < Error; end

  # raised when document not valid and using !
  class DocumentNotValid < Error
    attr_reader :document
  
    def initialize(document)
      @document = document
      super("Validation failed: #{document.errors.full_messages.join(", ")}")
    end
  end

  class AccessibleOrProtected < Error
    def initialize(name)
      super("Declare either attr_protected or attr_accessible for #{name}, but not both.")
    end
  end
end