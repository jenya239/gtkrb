require_relative '../../core/tree_events'

class TreeEventsTest
  def initialize
    @events = TreeEvents.new
    @passed = 0
    @failed = 0
  end
  
  def run_all_tests
    puts "=== TreeEvents Tests ==="
    
    test_on_method
    test_emit_method
    test_multiple_listeners
    test_clear_method
    test_has_listeners_method
    
    puts "\nResults: #{@passed} passed, #{@failed} failed"
    @failed == 0
  end
  
  private
  
  def test_on_method
    events = TreeEvents.new
    callback_called = false
    
    events.on(:test_event) { callback_called = true }
    events.emit(:test_event)
    
    assert(callback_called, "Callback should be called")
  end
  
  def test_emit_method
    events = TreeEvents.new
    received_args = nil
    
    events.on(:test_event) { |*args| received_args = args }
    events.emit(:test_event, "arg1", "arg2")
    
    assert(received_args == ["arg1", "arg2"], "Arguments should be passed correctly")
  end
  
  def test_multiple_listeners
    events = TreeEvents.new
    calls = []
    
    events.on(:test_event) { calls << "first" }
    events.on(:test_event) { calls << "second" }
    events.emit(:test_event)
    
    assert(calls == ["first", "second"], "Multiple listeners should be called")
  end
  
  def test_clear_method
    events = TreeEvents.new
    callback_called = false
    
    events.on(:test_event) { callback_called = true }
    events.clear(:test_event)
    events.emit(:test_event)
    
    assert(!callback_called, "Callback should not be called after clear")
  end
  
  def test_has_listeners_method
    events = TreeEvents.new
    
    assert(!events.has_listeners?(:test_event), "Should not have listeners initially")
    
    events.on(:test_event) { }
    assert(events.has_listeners?(:test_event), "Should have listeners after adding")
  end
  
  def assert(condition, message)
    if condition
      puts "✓ #{message}"
      @passed += 1
    else
      puts "✗ #{message}"
      @failed += 1
    end
  end
end

if __FILE__ == $0
  test = TreeEventsTest.new
  exit(test.run_all_tests ? 0 : 1)
end 