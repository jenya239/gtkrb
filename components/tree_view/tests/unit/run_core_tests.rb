#!/usr/bin/env ruby

require_relative 'tree_events_test'
require_relative 'tree_controller_test'
require_relative 'presentation_test'
require_relative 'input_test'

puts "Running Core, Presentation & Input Layer Unit Tests..."
puts "=" * 50

all_passed = true

# Run TreeEvents tests
events_test = TreeEventsTest.new
all_passed &= events_test.run_all_tests

puts

# Run TreeController tests
controller_test = TreeControllerTest.new
all_passed &= controller_test.run_all_tests

puts

# Run Presentation tests
presentation_test = PresentationTest.new
all_passed &= presentation_test.run_all_tests

puts

# Run Input tests
input_test = InputTest.new
all_passed &= input_test.run_all_tests

puts
puts "=" * 50
if all_passed
  puts "✓ All Core, Presentation & Input Layer tests passed!"
  exit 0
else
  puts "✗ Some tests failed"
  exit 1
end 