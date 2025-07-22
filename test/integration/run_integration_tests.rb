#!/usr/bin/env ruby

# Simple test runner for integration tests
Dir.glob("#{__dir__}/*.rb").each do |file|
  next if file.include?('run_integration_tests.rb')
  
  puts "Running #{File.basename(file)}..."
  system("ruby #{file}")
  puts "-" * 40
end 