module CustomMatchers
  custom_matcher :be_nil do |receiver, matcher, args|
    matcher.positive_failure_message = "Expected #{receiver} to be nil but it wasn't"
    matcher.negative_failure_message = "Expected #{receiver} not to be nil but it was"
    receiver.nil?
  end
  
  custom_matcher :be_blank do |receiver, matcher, args|
    matcher.positive_failure_message = "Expected #{receiver} to be blank but it wasn't"
    matcher.negative_failure_message = "Expected #{receiver} not to be blank but it was"
    receiver.blank?
  end
  
  custom_matcher :be_true do |receiver, matcher, args|
    matcher.positive_failure_message = "Expected #{receiver} to be true but it wasn't"
    matcher.negative_failure_message = "Expected #{receiver} not to be true but it was"
    receiver.eql?(true)
  end
  
  custom_matcher :be_false do |receiver, matcher, args|
    matcher.positive_failure_message = "Expected #{receiver} to be false but it wasn't"
    matcher.negative_failure_message = "Expected #{receiver} not to be false but it was"
    receiver.eql?(false)
  end

  custom_matcher :be_valid do |receiver, matcher, args|
    matcher.positive_failure_message = "Expected to be valid but it was invalid #{receiver.errors.inspect}"
    matcher.negative_failure_message = "Expected to be invalid but it was valid #{receiver.errors.inspect}"
    receiver.valid?
  end

  custom_matcher :have_error_on do |receiver, matcher, args|
    receiver.valid?
    attribute = args[0]
    expected_message = args[1]
    
    if expected_message.nil?
      matcher.positive_failure_message = "#{receiver} had no errors on #{attribute}"
      matcher.negative_failure_message = "#{receiver} had errors on #{attribute} #{receiver.errors.inspect}"
      !receiver.errors.on(attribute).blank?
    else
      actual = receiver.errors.on(attribute)
      matcher.positive_failure_message = %Q(Expected error on #{attribute} to be "#{expected_message}" but was "#{actual}")
      matcher.negative_failure_message = %Q(Expected error on #{attribute} not to be "#{expected_message}" but was "#{actual}")
      actual == expected_message
    end
  end
  
  custom_matcher :have_index do |receiver, matcher, args|
    index_name = args[0]
    matcher.positive_failure_message = "#{receiver} does not have index named #{index_name}, but should"
    matcher.negative_failure_message = "#{receiver} does have index named #{index_name}, but should not"
    !receiver.collection.index_information.detect { |index| index[0] == index_name }.nil?
  end
end