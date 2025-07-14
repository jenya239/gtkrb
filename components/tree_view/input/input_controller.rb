require_relative 'input_events'
require_relative 'navigation_engine'

class InputController
  def initialize(tree_controller, renderer)
    @tree_controller = tree_controller
    @renderer = renderer
    @navigation_engine = NavigationEngine.new(tree_controller)
    @last_click_time = 0
    @last_click_item = nil
    @double_click_threshold = 0.35
  end
  
  def handle_click(x, y, timestamp = nil)
    timestamp ||= Time.now.to_f
    
    item = @renderer.item_at_position(x, y, @tree_controller.state.scroll_offset)
    return false unless item
    
    # Проверяем на double click
    is_double_click = check_double_click(item, timestamp)
    
    if is_double_click
      handle_double_click(x, y)
    else
      handle_single_click(x, y)
    end
    
    true
  end
  
  def handle_single_click(x, y)
    @navigation_engine.handle_click(x, y, @renderer)
  end
  
  def handle_double_click(x, y)
    @navigation_engine.handle_double_click(x, y, @renderer)
  end
  
  def handle_key_press(key)
    # Нормализуем клавишу
    normalized_key = InputEvents.normalize_key(key)
    
    # Проверяем навигационные клавиши
    if InputEvents.is_navigation_key?(normalized_key)
      return @navigation_engine.handle_navigation_key(normalized_key)
    end
    
    # Проверяем action клавиши
    if InputEvents.is_action_key?(normalized_key)
      return @navigation_engine.handle_action_key(normalized_key)
    end
    
    # Специальные клавиши
    case normalized_key
    when InputEvents::KEY_ESCAPE
      handle_escape
    else
      false
    end
  end
  
  def handle_scroll(direction, amount = nil)
    @navigation_engine.handle_scroll(direction, amount)
  end
  
  def handle_mouse_move(x, y)
    # Обработка hover эффекта
    item = @renderer.item_at_position(x, y, @tree_controller.state.scroll_offset)
    
    if item != @tree_controller.state.hovered_item
      @tree_controller.state.hover_item(item)
      @tree_controller.events.emit(:hover_changed, item)
    end
    
    false
  end
  
  def handle_mouse_leave
    # Убираем hover при выходе мыши
    if @tree_controller.state.hovered_item
      @tree_controller.state.clear_hover
      @tree_controller.events.emit(:hover_changed, nil)
    end
    false
  end

  private
  
  def check_double_click(item, timestamp)
    time_diff = timestamp - @last_click_time
    same_item = (@last_click_item == item)
    
    @last_click_time = timestamp
    @last_click_item = item
    
    same_item && time_diff < @double_click_threshold
  end
  
  def handle_escape
    # Сбрасываем выделение или закрываем что-то
    false
  end
end 