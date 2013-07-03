def run_spec(file)
  unless File.exist?(file)
    puts "#{file} does not exist"
    return
  end

  puts "Running #{file}"
  system "bundle exec rspec #{file}"
  puts
end

watch("spec/.*/*_spec.rb") do |match|
  run_spec match[0]
end

def related_test_files(path)
  Dir.glob "spec/**/#{File.basename(path, File.extname(path))}_spec.rb"
end

watch('lib/.*') do |m|
  system('clear')
  if files = related_test_files(m[0]) and !files.empty?
    puts "bundle exec rspec #{files.join(" ")}"
    system "bundle exec rspec #{files.join(" ")}"
  end
end

Signal.trap('QUIT') do
  puts " --- Running all tests ---\n\n"
  run "rake"
end

# Ctrl-C
Signal.trap('INT') { abort("\n") }