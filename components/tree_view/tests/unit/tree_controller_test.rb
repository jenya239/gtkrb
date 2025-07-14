require_relative '../../core/tree_controller'
require_relative '../../core/tree_events'
require_relative '../../core/file_tree_model'
require_relative '../../src/file_tree_state'

class MockTreeModel
  def initialize
    @items = []
    @expandable_items = []
  end
  
  def add_item(name, expandable: false)
    item = MockItem.new(name, expandable)
    @items << item
    @expandable_items << item if expandable
    item
  end
  
  def can_expand?(item)
    @expandable_items.include?(item)
  end
  
  def get_flat_tree
    @items.map { |item| [item, 0] }
  end
  
  def get_root_items
    @items
  end
  
  def get_children(item)
    []
  end
  
  def change_directory(path)
    # Mock implementation
  end
  
  def current_path
    "/test/path"
  end
end

class MockItem
  attr_reader :name, :expandable
  
  def initialize(name, expandable)
    @name = name
    @expandable = expandable
  end
  
  def can_expand?
    @expandable
  end
  
  def to_s
    @name
  end
  
  def ==(other)
    other.is_a?(MockItem) && @name == other.name
  end
end



class TreeControllerTest
  def initialize
    @passed = 0
    @failed = 0
  end
  
  def run_all_tests
    puts "=== TreeController Tests ==="
    
    test_expand_item
    test_collapse_item
    test_toggle_expand
    test_select_item
    test_activate_item
    test_scroll_methods
    test_navigation
    test_key_handling
    
    puts "\nResults: #{@passed} passed, #{@failed} failed"
    @failed == 0
  end
  
  private
  
  def test_expand_item
    model = MockTreeModel.new
    state = FileTreeState.new
    events = TreeEvents.new
    controller = TreeController.new(model, state, events)
    
    item = model.add_item("folder", expandable: true)
    events_emitted = []
    events.on(:tree_changed) { |item| events_emitted << item }
    
    controller.expand_item(item)
    
    assert(state.expanded?(item), "Item should be expanded")
    assert(events_emitted.include?(item), "tree_changed event should be emitted")
  end
  
  def test_collapse_item
    model = MockTreeModel.new
    state = FileTreeState.new
    events = TreeEvents.new
    controller = TreeController.new(model, state, events)
    
    item = model.add_item("folder", expandable: true)
    controller.expand_item(item)  # Use controller instead of state directly
    events_emitted = []
    events.on(:tree_changed) { |item| events_emitted << item }
    
    controller.collapse_item(item)
    
    assert(!state.expanded?(item), "Item should be collapsed")
    assert(events_emitted.include?(item), "tree_changed event should be emitted")
  end
  
  def test_toggle_expand
    model = MockTreeModel.new
    state = FileTreeState.new
    events = TreeEvents.new
    controller = TreeController.new(model, state, events)
    
    item = model.add_item("folder", expandable: true)
    
    # Test expand
    controller.toggle_expand(item)
    assert(state.expanded?(item), "Item should be expanded after toggle")
    
    # Test collapse
    controller.toggle_expand(item)
    assert(!state.expanded?(item), "Item should be collapsed after second toggle")
  end
  
  def test_select_item
    model = MockTreeModel.new
    state = FileTreeState.new
    events = TreeEvents.new
    controller = TreeController.new(model, state, events)
    
    item = model.add_item("file")
    selected_items = []
    events.on(:item_selected) { |item| selected_items << item }
    
    controller.select_item(item)
    
    assert(state.selected_item == item, "Item should be selected")
    assert(selected_items.include?(item), "item_selected event should be emitted")
  end
  
  def test_activate_item
    model = MockTreeModel.new
    state = FileTreeState.new
    events = TreeEvents.new
    controller = TreeController.new(model, state, events)
    
    item = model.add_item("file")
    activated_items = []
    events.on(:item_activated) { |item| activated_items << item }
    
    controller.activate_item(item)
    
    assert(activated_items.include?(item), "item_activated event should be emitted")
  end
  
  def test_scroll_methods
    model = MockTreeModel.new
    state = FileTreeState.new
    events = TreeEvents.new
    controller = TreeController.new(model, state, events)
    
    events_emitted = []
    events.on(:view_changed) { events_emitted << :view_changed }
    
    controller.scroll_to(100)
    assert(state.scroll_offset == 100, "Scroll offset should be set")
    assert(events_emitted.include?(:view_changed), "view_changed event should be emitted")
    
    controller.scroll_by(50)
    assert(state.scroll_offset == 150, "Scroll offset should be incremented")
  end
  
  def test_navigation
    model = MockTreeModel.new
    state = FileTreeState.new
    events = TreeEvents.new
    controller = TreeController.new(model, state, events)
    
    item1 = model.add_item("file1")
    item2 = model.add_item("file2")
    item3 = model.add_item("file3")
    
    controller.select_item(item1)
    
    controller.select_next
    assert(state.selected_item == item2, "Should select next item")
    
    controller.select_previous
    assert(state.selected_item == item1, "Should select previous item")
  end
  
  def test_key_handling
    model = MockTreeModel.new
    state = FileTreeState.new
    events = TreeEvents.new
    controller = TreeController.new(model, state, events)
    
    item1 = model.add_item("file1")
    item2 = model.add_item("file2")
    folder = model.add_item("folder", expandable: true)
    
    controller.select_item(item1)
    
    # Test navigation keys
    controller.handle_key(:down)
    assert(state.selected_item == item2, "Down key should select next item")
    
    controller.handle_key(:up)
    assert(state.selected_item == item1, "Up key should select previous item")
    
    # Test activation
    activated_items = []
    events.on(:item_activated) { |item| activated_items << item }
    
    controller.handle_key(:enter)
    assert(activated_items.include?(item1), "Enter key should activate item")
    
    # Test expansion
    controller.select_item(folder)
    controller.handle_key(:space)
    assert(state.expanded?(folder), "Space key should toggle expand")
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
  test = TreeControllerTest.new
  exit(test.run_all_tests ? 0 : 1)
end 