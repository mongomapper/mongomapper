RSpec::Matchers.define :have_error_on do |*args|
  @message = nil
  @attributes = [args]

  chain :or do |*args|
    @attributes << args
  end

  match do |model|
    model.valid?
    @has_errors = @attributes.detect {|attribute| model.errors[attribute[0]].present? }
    if @message
      !!@has_errors && model.errors[@has_errors[0]].include?(@has_errors[1])
    else
      !!@has_errors
    end
  end
end

RSpec::Matchers.define :have_index do |index_name|
  match do |model|
    model.collection.index_information.detect { |index| index[0] == index_name }.present?
  end
end