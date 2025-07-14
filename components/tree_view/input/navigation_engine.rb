require_relative 'input_events'

class NavigationEngine
  def initialize(tree_controller)
    @tree_controller = tree_controller
  end
  
  def handle_navigation_key(key)
    case key
    when InputEvents::KEY_UP
      @tree_controller.select_previous
    when InputEvents::KEY_DOWN
      @tree_controller.select_next
    when InputEvents::KEY_LEFT
      handle_left_key
    when InputEvents::KEY_RIGHT
      handle_right_key
    when InputEvents::KEY_HOME
      select_first_item
    when InputEvents::KEY_END
      select_last_item
    when InputEvents::KEY_PAGE_UP
      page_up
    when InputEvents::KEY_PAGE_DOWN
      page_down
    else
      false
    end
    true
  end
  
  def handle_action_key(key)
    return false unless @tree_controller.state.selected_item
    
    case key
    when InputEvents::KEY_ENTER
      @tree_controller.activate_item(@tree_controller.state.selected_item)
    when InputEvents::KEY_SPACE
      @tree_controller.toggle_expand(@tree_controller.state.selected_item)
    else
      return false
    end
    true
  end
  
  def handle_scroll(direction, amount = nil)
    amount ||= default_scroll_amount
    
    case direction
    when InputEvents::SCROLL_UP
      @tree_controller.scroll_by(-amount)
    when InputEvents::SCROLL_DOWN
      @tree_controller.scroll_by(amount)
    else
      return false
    end
    true
  end
  
  def handle_click(x, y, renderer)
    item = renderer.item_at_position(x, y, @tree_controller.state.scroll_offset)
    return false unless item
    
    @tree_controller.select_item(item)
    
    # Если это папка, разворачиваем/сворачиваем ее
    if item.type == :directory
      @tree_controller.toggle_expand(item)
    end
    
    true
  end
  
  def handle_double_click(x, y, renderer)
    item = renderer.item_at_position(x, y, @tree_controller.state.scroll_offset)
    return false unless item
    
    @tree_controller.activate_item(item)
    true
  end
  
  private
  
  def handle_left_key
    selected = @tree_controller.state.selected_item
    return unless selected
    
    if @tree_controller.state.expanded?(selected)
      # Если элемент раскрыт, сворачиваем его
      @tree_controller.collapse_item(selected)
    else
      # Если элемент свернут, переходим к родителю
      select_parent_item(selected)
    end
  end
  
  def handle_right_key
    selected = @tree_controller.state.selected_item
    return unless selected
    
    if @tree_controller.model.can_expand?(selected)
      if @tree_controller.state.expanded?(selected)
        # Если уже раскрыт, переходим к первому дочернему элементу
        select_first_child(selected)
      else
        # Если свернут, раскрываем
        @tree_controller.expand_item(selected)
      end
    end
  end
  
  def select_first_item
    items = @tree_controller.get_visible_items
    return if items.empty?
    
    @tree_controller.select_item(items.first.first)
  end
  
  def select_last_item
    items = @tree_controller.get_visible_items
    return if items.empty?
    
    @tree_controller.select_item(items.last.first)
  end
  
  def page_up
    # Перемещаемся на страницу вверх
    items = @tree_controller.get_visible_items
    return if items.empty?
    
    selected = @tree_controller.state.selected_item
    current_index = items.index { |item, _| item == selected } || 0
    
    page_size = calculate_page_size
    new_index = [current_index - page_size, 0].max
    
    @tree_controller.select_item(items[new_index].first)
  end
  
  def page_down
    # Перемещаемся на страницу вниз
    items = @tree_controller.get_visible_items
    return if items.empty?
    
    selected = @tree_controller.state.selected_item
    current_index = items.index { |item, _| item == selected } || 0
    
    page_size = calculate_page_size
    new_index = [current_index + page_size, items.size - 1].min
    
    @tree_controller.select_item(items[new_index].first)
  end
  
  def select_parent_item(item)
    # Простая реализация - переходим к предыдущему элементу с меньшим уровнем
    items = @tree_controller.get_visible_items
    current_index = items.index { |it, _| it == item }
    return unless current_index
    
    current_level = items[current_index][1]
    
    # Ищем родительский элемент (меньший уровень)
    (current_index - 1).downto(0) do |i|
      if items[i][1] < current_level
        @tree_controller.select_item(items[i][0])
        break
      end
    end
  end
  
  def select_first_child(item)
    # Находим первый дочерний элемент
    items = @tree_controller.get_visible_items
    current_index = items.index { |it, _| it == item }
    return unless current_index
    
    current_level = items[current_index][1]
    
    # Ищем первый дочерний элемент (больший уровень)
    if current_index + 1 < items.size && items[current_index + 1][1] > current_level
      @tree_controller.select_item(items[current_index + 1][0])
    end
  end
  
  def calculate_page_size
    # Примерный размер страницы (можно настроить)
    10
  end
  
  def default_scroll_amount
    # Стандартное количество пикселей для скролла
    60
  end
end 