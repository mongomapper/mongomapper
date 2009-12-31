class Test::Unit::TestCase
  def run_with_test_timing(*args, &block)    
    begin_time = Time.now
    run_without_test_timing(*args, &block)
    end_time = Time.now
 
    duration = end_time - begin_time
    threshold = 1.0
    
    if duration > threshold
      puts "\nSLOW TEST: #{duration} - #{self.name}"
    end
  end
  
  alias_method_chain :run, :test_timing unless method_defined?(:run_without_test_timing)
end