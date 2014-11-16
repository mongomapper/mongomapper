RSpec::Matchers.define :have_error_on do |*args|
  match do |model|
    field = args.dup.shift
    error_messages = args

    model.valid?
    model.errors[field].any?
  end
end

RSpec::Matchers.define :have_index do |index_name|
  match do |model|
    model.collection.index_information.detect { |index| index[0] == index_name }.present?
  end
end