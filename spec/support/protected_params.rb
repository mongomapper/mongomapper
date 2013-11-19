class ProtectedParams < ActiveSupport::HashWithIndifferentAccess
  attr_accessor :permitted
  alias :permitted? :permitted

  def initialize(attributes)
    super(attributes)
    @permitted = false
  end

  def permit!
    @permitted = true
    self
  end
end
