require_relative '../../input/input_events'
require_relative '../../input/navigation_engine'
require_relative '../../input/input_controller'

# Mock objects для тестирования
class MockTreeController
  attr_reader :state, :model
  attr_accessor :selected_item, :expanded_items
  
  def initialize
    @state = MockInputState.new
    @model = MockModel.new
    @selected_item = nil
    @expanded_items = []
    @items = []
    @commands = []
  end
  
  def add_item(name, expandable: false)
    item = MockInputItem.new(name, expandable)
    @items << item
    item
  end
  
  def select_item(item)
    @selected_item = item
    @state.selected_item = item
    record_command(:select_item, item)
  end
  
  def select_previous
    index = @items.index(@selected_item) || 0
    new_index = [index - 1, 0].max
    select_item(@items[new_index])
    record_command(:select_previous)
  end
  
  def select_next
    index = @items.index(@selected_item) || -1
    new_index = [index + 1, @items.size - 1].min
    select_item(@items[new_index])
    record_command(:select_next)
  end
  
  def expand_item(item)
    @expanded_items << item unless @expanded_items.include?(item)
    record_command(:expand_item, item)
  end
  
  def collapse_item(item)
    @expanded_items.delete(item)
    record_command(:collapse_item, item)
  end
  
  def toggle_expand(item)
    if @expanded_items.include?(item)
      collapse_item(item)
    else
      expand_item(item)
    end
    record_command(:toggle_expand, item)
  end
  
  def activate_item(item)
    record_command(:activate_item, item)
  end
  
  def scroll_by(amount)
    @state.scroll_offset += amount
    record_command(:scroll_by, amount)
  end
  
  def get_visible_items
    @items.map.with_index { |item, index| [item, 0] }
  end
  
  def commands
    @commands
  end
  
  private
  
  def record_command(command, *args)
    @commands << [command, *args]
  end
end

class MockInputState
  attr_accessor :selected_item, :scroll_offset
  
  def initialize
    @selected_item = nil
    @scroll_offset = 0
  end
  
  def expanded?(item)
    false
  end
end

class MockModel
  def can_expand?(item)
    item&.expandable?
  end
end

class MockInputItem
  attr_reader :name, :expandable
  
  def initialize(name, expandable = false)
    @name = name
    @expandable = expandable
  end
  
  def expandable?
    @expandable
  end
  
  def ==(other)
    other.is_a?(MockInputItem) && @name == other.name
  end
end

class MockInputRenderer
  def initialize
    @items = []
  end
  
  def set_items(items)
    @items = items
  end
  
  def item_at_position(x, y, scroll_offset)
    # Простая реализация - возвращаем первый элемент если есть
    @items.first
  end
end

class InputTest
  def initialize
    @passed = 0
    @failed = 0
  end
  
  def run_all_tests
    puts "=== Input Layer Tests ==="
    
    test_input_events
    test_navigation_engine
    test_input_controller
    
    puts "\nResults: #{@passed} passed, #{@failed} failed"
    @failed == 0
  end
  
  private
  
  def test_input_events
    # Test key normalization
    assert(InputEvents.normalize_key(:return) == :enter, "Return key should be normalized to enter")
    assert(InputEvents.normalize_key(:up) == :up, "Up key should remain up")
    
    # Test key type checking
    assert(InputEvents.is_navigation_key?(:up), "Up should be navigation key")
    assert(InputEvents.is_navigation_key?(:home), "Home should be navigation key")
    assert(!InputEvents.is_navigation_key?(:enter), "Enter should not be navigation key")
    
    assert(InputEvents.is_action_key?(:enter), "Enter should be action key")
    assert(InputEvents.is_action_key?(:space), "Space should be action key")
    assert(!InputEvents.is_action_key?(:up), "Up should not be action key")
  end
  
  def test_navigation_engine
    controller = MockTreeController.new
    engine = NavigationEngine.new(controller)
    
    # Добавляем тестовые элементы
    item1 = controller.add_item("item1")
    item2 = controller.add_item("item2")
    folder = controller.add_item("folder", expandable: true)
    
    controller.select_item(item1)
    
    # Test navigation keys
    engine.handle_navigation_key(:down)
    assert(controller.selected_item == item2, "Should select next item on down")
    
    engine.handle_navigation_key(:up)
    assert(controller.selected_item == item1, "Should select previous item on up")
    
    engine.handle_navigation_key(:home)
    assert(controller.selected_item == item1, "Should select first item on home")
    
    engine.handle_navigation_key(:end)
    assert(controller.selected_item == folder, "Should select last item on end")
    
    # Test action keys
    controller.select_item(folder)
    engine.handle_action_key(:space)
    assert(controller.expanded_items.include?(folder), "Should expand folder on space")
    
    engine.handle_action_key(:enter)
    commands = controller.commands
    activate_command = commands.find { |cmd| cmd[0] == :activate_item }
    assert(activate_command && activate_command[1] == folder, "Should activate item on enter")
    
    # Test scroll
    engine.handle_scroll(:scroll_down, 50)
    assert(controller.state.scroll_offset == 50, "Should scroll down by 50")
    
    engine.handle_scroll(:scroll_up, 30)
    assert(controller.state.scroll_offset == 20, "Should scroll up by 30")
  end
  
  def test_input_controller
    tree_controller = MockTreeController.new
    renderer = MockInputRenderer.new
    input_controller = InputController.new(tree_controller, renderer)
    
    # Добавляем тестовый элемент
    item = tree_controller.add_item("test_item")
    renderer.set_items([item])
    
    # Test click handling
    result = input_controller.handle_click(10, 20)
    assert(result, "Should handle click successfully")
    
    # Test key handling
    result = input_controller.handle_key_press(:up)
    assert(result, "Should handle up key")
    
    result = input_controller.handle_key_press(:enter)
    assert(result, "Should handle enter key")
    
    # Test scroll handling
    result = input_controller.handle_scroll(:scroll_down)
    assert(result, "Should handle scroll")
    
    # Test double click detection
    timestamp1 = Time.now.to_f
    input_controller.handle_click(10, 20, timestamp1)
    
    timestamp2 = timestamp1 + 0.2  # Within double click threshold
    result = input_controller.handle_click(10, 20, timestamp2)
    assert(result, "Should handle double click")
    
    # Check that activate command was called
    commands = tree_controller.commands
    activate_command = commands.find { |cmd| cmd[0] == :activate_item }
    assert(activate_command != nil, "Should have activate command for double click")
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
  test = InputTest.new
  exit(test.run_all_tests ? 0 : 1)
end 