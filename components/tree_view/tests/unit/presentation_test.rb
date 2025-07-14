require_relative '../../presentation/tree_theme'
require_relative '../../presentation/tree_layout'
require_relative '../../presentation/abstract_renderer'
require_relative '../../presentation/render_context'
require_relative '../../src/file_tree_item'

class MockRenderContext < RenderContext
  attr_reader :rectangles, :texts, :icons, :lines, :background_color
  
  def initialize(width = 200, height = 300, theme = nil)
    super(width, height, theme)
    @rectangles = []
    @texts = []
    @icons = []
    @lines = []
    @background_color = nil
  end
  
  def draw_rectangle(x, y, width, height, color)
    @rectangles << { x: x, y: y, width: width, height: height, color: color }
  end
  
  def draw_text(x, y, text, font_size, color)
    @texts << { x: x, y: y, text: text, font_size: font_size, color: color }
  end
  
  def draw_icon(x, y, icon_type)
    @icons << { x: x, y: y, icon_type: icon_type }
  end
  
  def draw_line(x1, y1, x2, y2, color, width = 1)
    @lines << { x1: x1, y1: y1, x2: x2, y2: y2, color: color, width: width }
  end
  
  def clear_background(color)
    @background_color = color
  end
end

class MockPresentationState
  attr_reader :selected_item, :expanded_items
  attr_accessor :scroll_offset
  
  def initialize
    @selected_item = nil
    @expanded_items = []
    @scroll_offset = 0
  end
  
  def expanded?(item)
    @expanded_items.include?(item)
  end
  
  def set_selected(item)
    @selected_item = item
  end
  
  def set_expanded(item)
    @expanded_items << item unless @expanded_items.include?(item)
  end
end

class MockRenderer < AbstractRenderer
  attr_reader :rendered_items, :background_rendered
  
  def initialize(theme)
    super(theme)
    @rendered_items = []
    @background_rendered = false
  end
  
  def render_background(context)
    @background_rendered = true
    super(context)
  end
  
  def render_item(context, item, level, y, state)
    @rendered_items << {
      item: item,
      level: level,
      y: y,
      selected: item == state.selected_item,
      expanded: state.expanded?(item)
    }
    super(context, item, level, y, state)
  end
end

class PresentationTest
  def initialize
    @passed = 0
    @failed = 0
  end
  
  def run_all_tests
    puts "=== Presentation Layer Tests ==="
    
    test_tree_theme
    test_tree_layout
    test_abstract_renderer
    
    puts "\nResults: #{@passed} passed, #{@failed} failed"
    @failed == 0
  end
  
  private
  
  def test_tree_theme
    theme = TreeTheme.new
    
    assert(theme.item_height == 20, "Item height should be 20")
    assert(theme.icon_x(0) == 2, "Icon x for level 0 should be 2")
    assert(theme.icon_x(1) == 16, "Icon x for level 1 should be 16")
    assert(theme.text_x(0) == 20, "Text x for level 0 should be 20")
    assert(theme.background_color.is_a?(Array), "Background color should be array")
  end
  
  def test_tree_layout
    theme = TreeTheme.new
    layout = TreeLayout.new(theme)
    
    # Test initial state
    assert(layout.needs_update?, "Layout should need update initially")
    assert(layout.cached_items.empty?, "Cached items should be empty initially")
    
    # Test layout update
    items = [
      [create_item("file1.txt", :file), 0],
      [create_item("folder1", :directory), 0],
      [create_item("file2.txt", :file), 1]
    ]
    
    layout.update_layout(items)
    
    assert(!layout.needs_update?, "Layout should not need update after updating")
    assert(layout.cached_items.size == 3, "Should have 3 cached items")
    assert(layout.total_height == 60, "Total height should be 60 (3 * 20)")
    
    # Test visible range
    start_idx, end_idx = layout.get_visible_range(40, 0)
    assert(start_idx == 0, "Start index should be 0")
    assert(end_idx == 2, "End index should be 2")
    
    # Test item at position
    item = layout.item_at_position(10, 25, 0)
    assert(item.name == "folder1", "Item at position should be folder1")
  end
  
  def test_abstract_renderer
    theme = TreeTheme.new
    renderer = MockRenderer.new(theme)
    context = MockRenderContext.new(200, 300, theme)
    state = MockPresentationState.new
    
    # Create test items
    items = [
      [create_item("file1.txt", :file), 0],
      [create_item("folder1", :directory), 0]
    ]
    
    # Test rendering
    renderer.render_tree(context, items, state)
    
    assert(renderer.background_rendered, "Background should be rendered")
    assert(renderer.rendered_items.size == 2, "Should render 2 items")
    assert(context.background_color == theme.background_color, "Background color should match theme")
    
    # Test item rendering details
    first_item = renderer.rendered_items[0]
    assert(first_item[:item].name == "file1.txt", "First item should be file1.txt")
    assert(first_item[:level] == 0, "First item level should be 0")
    assert(first_item[:y] == 0, "First item y should be 0")
    
    # Test selection rendering
    state.set_selected(items[0][0])
    renderer.render_tree(context, items, state)
    
    selection_rect = context.rectangles.find { |r| r[:color] == theme.selection_color }
    assert(selection_rect != nil, "Selection rectangle should be drawn")
    
    # Test text rendering
    text_item = context.texts.find { |t| t[:text] == "file1.txt" }
    assert(text_item != nil, "Text should be rendered")
    assert(text_item[:color] == theme.text_color, "Text color should match theme")
    
    # Test icon rendering
    icon_item = context.icons.find { |i| i[:icon_type] == :file }
    assert(icon_item != nil, "Icon should be rendered")
    
    # Test expander rendering for expandable items
    items = [[create_item("folder1", :directory), 0]]
    renderer.render_tree(context, items, state)
    
    # Should have expander lines
    assert(context.lines.size > 0, "Should have expander lines")
  end
  
  def create_item(name, type)
    FileTreeItem.new(name: name, path: "/test/#{name}", type: type)
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
  test = PresentationTest.new
  exit(test.run_all_tests ? 0 : 1)
end 