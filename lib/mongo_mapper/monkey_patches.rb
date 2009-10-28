class Symbol
  %w{gt lt gte lte ne in nin mod size where exists}.each do |operator|
    define_method operator do
      MongoMapper::FinderOperator.new(self, "$#{operator}")
    end
  end
end