#!/usr/bin/env ruby

# Интеграционный тест для новой архитектуры Tree View
# Проверяет что все слои работают вместе

require_relative '../platform/gtk3/gtk3_tree_widget'
require_relative '../../../lib/ui/file_explorer'

puts "=== Final Integration Test ==="
puts "Testing new layered architecture..."

class IntegrationTest
  def initialize
    @passed = 0
    @failed = 0
  end
  
  def run_all_tests
    test_gtk3_tree_widget
    test_file_explorer_integration
    test_events_and_callbacks
    test_navigation_and_input
    
    puts "\n" + "="*50
    if @failed == 0
      puts "✅ All integration tests passed! (#{@passed}/#{@passed})"
      puts "🎉 New layered architecture is working correctly!"
      true
    else
      puts "❌ Some integration tests failed! (#{@passed}/#{@passed + @failed})"
      false
    end
  end
  
  private
  
  def test_gtk3_tree_widget
    puts "\n--- Testing GTK3TreeWidget ---"
    
    # Создаем виджет
    widget = GTK3TreeWidget.new("/tmp")
    assert(widget.is_a?(GTK3TreeWidget), "Should create GTK3TreeWidget")
    
    # Проверяем слои
    assert(widget.tree_controller.is_a?(TreeController), "Should have TreeController")
    assert(widget.renderer.is_a?(GTK3CairoRenderer), "Should have GTK3CairoRenderer")
    assert(widget.input_controller.is_a?(InputController), "Should have InputController")
    
    # Проверяем методы
    assert(widget.current_path == "/tmp", "Should have correct current path")
    assert(widget.respond_to?(:refresh), "Should have refresh method")
    assert(widget.respond_to?(:change_directory), "Should have change_directory method")
    
    puts "✓ GTK3TreeWidget tests passed"
  end
  
  def test_file_explorer_integration
    puts "\n--- Testing FileExplorer Integration ---"
    
    # Создаем FileExplorer
    explorer = FileExplorer.new
    assert(explorer.respond_to?(:widget), "Should have widget method")
    assert(explorer.respond_to?(:on_file_selected), "Should have on_file_selected method")
    assert(explorer.respond_to?(:refresh), "Should have refresh method")
    assert(explorer.respond_to?(:load_directory), "Should have load_directory method")
    
    # Проверяем что widget это GTK виджет
    widget = explorer.widget
    assert(widget.is_a?(Gtk::Widget), "Should return GTK widget")
    
    puts "✓ FileExplorer integration tests passed"
  end
  
  def test_events_and_callbacks
    puts "\n--- Testing Events and Callbacks ---"
    
    widget = GTK3TreeWidget.new("/tmp")
    
    # Тестируем коллбеки
    item_selected = false
    item_activated = false
    directory_changed = false
    
    widget.on_item_selected { |item| item_selected = true }
    widget.on_item_activated { |item| item_activated = true }
    widget.on_directory_changed { |path| directory_changed = true }
    
    # Симулируем события через TreeController
    items = widget.tree_controller.get_visible_items
    if items.any?
      widget.tree_controller.select_item(items.first.first)
      assert(item_selected, "Should trigger item_selected callback")
      
      widget.tree_controller.activate_item(items.first.first)
      assert(item_activated, "Should trigger item_activated callback")
    end
    
    # Смена директории
    widget.change_directory("/home")
    assert(directory_changed, "Should trigger directory_changed callback")
    
    puts "✓ Events and callbacks tests passed"
  end
  
  def test_navigation_and_input
    puts "\n--- Testing Navigation and Input ---"
    
    widget = GTK3TreeWidget.new("/tmp")
    
    # Тестируем навигацию
    items = widget.tree_controller.get_visible_items
    if items.size > 1
      widget.tree_controller.select_item(items.first.first)
      first_selected = widget.tree_controller.state.selected_item
      
      widget.tree_controller.select_next
      second_selected = widget.tree_controller.state.selected_item
      
      assert(first_selected != second_selected, "Should navigate to next item")
      
      widget.tree_controller.select_previous
      back_selected = widget.tree_controller.state.selected_item
      
      assert(first_selected == back_selected, "Should navigate back to previous item")
    end
    
    # Тестируем input controller
    input_controller = widget.input_controller
    assert(input_controller.respond_to?(:handle_click), "Should handle clicks")
    assert(input_controller.respond_to?(:handle_key_press), "Should handle key press")
    assert(input_controller.respond_to?(:handle_scroll), "Should handle scroll")
    
    puts "✓ Navigation and input tests passed"
  end
  
  def assert(condition, message)
    if condition
      puts "  ✓ #{message}"
      @passed += 1
    else
      puts "  ✗ #{message}"
      @failed += 1
    end
  end
end

# Запускаем тест
test = IntegrationTest.new
success = test.run_all_tests

exit(success ? 0 : 1) 