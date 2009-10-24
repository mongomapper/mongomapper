def run(cmd)
  puts(cmd)
  system(cmd)
end

def run_test_file(file)
  run %Q(ruby -I"lib:test" -rubygems #{file})
end

def run_all_tests
  run "rake test"
end

def related_test_files(path)
  Dir['test/**/*.rb'].select { |file| file =~ /test_#{File.basename(path)}/ }
end

watch('test/test_helper\.rb') { run_all_tests }
watch('test/.*/test_.*\.rb')  { |m| run_test_file(m[0]) }
watch('lib/.*') do |m|
  related_test_files(m[0]).each { |file| run_test_file(file) }
end

# Ctrl-\
Signal.trap('QUIT') do
  puts " --- Running all tests ---\n\n"
  run_all_tests
end

# Ctrl-C
Signal.trap('INT') { abort("\n") }

