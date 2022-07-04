module Options
  # @api public
  def filter_attributes=(attributes)
    @filter_attributes = attributes
  end

  # @api public
  def filter_attributes
    @filter_attributes || []
  end
end
