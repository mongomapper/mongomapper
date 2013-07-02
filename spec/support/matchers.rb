RSpec::Matchers.define :have_error_on do |attribute|
  chain :with_message do |message|
    @message = message
  end

  match do |model|
    model.valid?
    @has_errors = model.errors[attribute].present?
    if @message
      @has_errors && model.errors[attribute].include?(@message)
    else
      @has_errors
    end
  end
end

RSpec::Matchers.define :have_index do |index_name|
  match do |model|
    model.collection.index_information.detect { |index| index[0] == index_name }.present?
  end
end