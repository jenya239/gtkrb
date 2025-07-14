# Architecture Examples

## 1. Core Layer - Framework-agnostic

### TreeController
```ruby
class TreeController
  def initialize(model, state, events)
    @model = model
    @state = state
    @events = events
  end
  
  def expand_item(item)
    return unless @model.can_expand?(item)
    @state.expand(item)
    @events.emit(:tree_changed)
  end
  
  def select_item(item)
    @state.select(item)
    @events.emit(:item_selected, item)
  end
  
  def scroll_to(offset)
    @state.set_scroll_offset(offset)
    @events.emit(:view_changed)
  end
  
  def handle_key(key)
    case key
    when :up then select_previous
    when :down then select_next
    when :enter then activate_selected
    end
  end
end
```

### TreeEvents
```ruby
class TreeEvents
  def initialize
    @listeners = {}
  end
  
  def on(event, &block)
    @listeners[event] ||= []
    @listeners[event] << block
  end
  
  def emit(event, *args)
    @listeners[event]&.each { |block| block.call(*args) }
  end
end
```

## 2. Presentation Layer - Framework-agnostic

### AbstractRenderer
```ruby
class AbstractRenderer
  def initialize(theme)
    @theme = theme
  end
  
  def render_tree(context, items, state)
    render_background(context)
    
    items.each_with_index do |(item, level), index|
      y = index * @theme.item_height - state.scroll_offset
      render_item(context, item, level, y, state)
    end
  end
  
  def render_item(context, item, level, y, state)
    # Абстрактный метод - реализуется в конкретных рендерерах
    raise NotImplementedError
  end
  
  def render_background(context)
    raise NotImplementedError
  end
end
```

### RenderContext
```ruby
class RenderContext
  attr_reader :width, :height, :icons
  
  def initialize(width, height, icon_loader)
    @width = width
    @height = height
    @icons = icon_loader
  end
  
  def draw_rectangle(x, y, width, height, color)
    raise NotImplementedError
  end
  
  def draw_text(x, y, text, font, color)
    raise NotImplementedError
  end
  
  def draw_icon(x, y, icon)
    raise NotImplementedError
  end
end
```

## 3. Input Layer - Framework-agnostic

### InputController
```ruby
class InputController
  def initialize(tree_controller)
    @tree_controller = tree_controller
  end
  
  def handle_click(x, y, double_click: false)
    item = find_item_at_position(x, y)
    return unless item
    
    if double_click
      @tree_controller.activate_item(item)
    else
      @tree_controller.select_item(item)
    end
  end
  
  def handle_key(key)
    @tree_controller.handle_key(key)
  end
  
  def handle_scroll(delta)
    @tree_controller.scroll_by(delta)
  end
end
```

## 4. Platform Layer - GTK3 specific

### GTK3TreeWidget
```ruby
class GTK3TreeWidget < Gtk::DrawingArea
  def initialize(tree_controller, renderer)
    super()
    @tree_controller = tree_controller
    @renderer = renderer
    @event_adapter = GTK3EventAdapter.new(self, tree_controller)
    
    setup_gtk_events
  end
  
  def setup_gtk_events
    signal_connect("draw") { |_, cr| draw(cr) }
    @event_adapter.setup_events
  end
  
  private
  
  def draw(cr)
    context = GTK3RenderContext.new(cr, allocation.width, allocation.height)
    @renderer.render_tree(context, @tree_controller.get_visible_items, @tree_controller.state)
    false
  end
end
```

### GTK3EventAdapter
```ruby
class GTK3EventAdapter
  def initialize(widget, input_controller)
    @widget = widget
    @input_controller = input_controller
  end
  
  def setup_events
    @widget.signal_connect("button-press-event") { |_, event| handle_gtk_click(event) }
    @widget.signal_connect("key-press-event") { |_, event| handle_gtk_key(event) }
    @widget.signal_connect("scroll-event") { |_, event| handle_gtk_scroll(event) }
  end
  
  private
  
  def handle_gtk_click(event)
    @input_controller.handle_click(event.x, event.y, double_click: event.type == Gdk::EventType::DOUBLE_BUTTON_PRESS)
    false
  end
  
  def handle_gtk_key(event)
    key = map_gtk_key(event.keyval)
    @input_controller.handle_key(key)
    false
  end
  
  def map_gtk_key(keyval)
    case keyval
    when Gdk::Keyval::KEY_Up then :up
    when Gdk::Keyval::KEY_Down then :down
    when Gdk::Keyval::KEY_Return then :enter
    end
  end
end
```

### GTK3CairoRenderer < AbstractRenderer
```ruby
class GTK3CairoRenderer < AbstractRenderer
  def render_background(context)
    context.cairo.set_source_rgba(*@theme.background_color)
    context.cairo.paint
  end
  
  def render_item(context, item, level, y, state)
    cr = context.cairo
    
    # Background
    if state.selected?(item)
      cr.set_source_rgba(*@theme.selection_color)
      cr.rectangle(0, y, context.width, @theme.item_height)
      cr.fill
    end
    
    # Icon
    icon_x = level * @theme.indent + 5
    icon = context.icons.get_icon(item.type)
    context.draw_icon(icon_x, y + 2, icon)
    
    # Text
    text_x = icon_x + @theme.icon_size + 5
    text_y = y + @theme.item_height - 3
    context.draw_text(text_x, text_y, item.name, @theme.font, @theme.text_color)
  end
end
```

## Использование

```ruby
# Создание компонента
model = FileTreeModel.new(root_path)
state = TreeState.new
events = TreeEvents.new
controller = TreeController.new(model, state, events)

# Renderer
theme = TreeTheme.new
renderer = GTK3CairoRenderer.new(theme)

# Input
input_controller = InputController.new(controller)

# GTK Widget
widget = GTK3TreeWidget.new(controller, renderer)

# События
events.on(:item_selected) { |item| puts "Selected: #{item.name}" }
events.on(:item_activated) { |item| puts "Activated: #{item.name}" }
```

## Тестирование

```ruby
# Тестирование без GUI
describe TreeController do
  it "expands items" do
    model = MockTreeModel.new
    state = TreeState.new
    events = TreeEvents.new
    controller = TreeController.new(model, state, events)
    
    item = model.root_items.first
    controller.expand_item(item)
    
    expect(state.expanded?(item)).to be true
  end
end
``` 