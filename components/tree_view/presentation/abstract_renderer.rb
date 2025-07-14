require_relative 'tree_layout'

class AbstractRenderer
  attr_reader :theme, :layout
  
  def initialize(theme)
    @theme = theme
    @layout = TreeLayout.new(theme)
  end
  
  def render_tree(context, items, state)
    # Обновляем layout если нужно
    if @layout.needs_update?
      @layout.update_layout(items)
    end
    
    # Очищаем фон
    render_background(context)
    
    # Получаем видимые элементы
    visible_items = @layout.get_visible_items(context.height, state.scroll_offset)
    
    # Рендерим каждый видимый элемент
    visible_items.each do |item_data, y_position|
      item, level = item_data
      render_item(context, item, level, y_position, state)
    end
  end
  
  def render_background(context)
    context.clear_background(@theme.background_color)
  end
  
  def render_item(context, item, level, y, state)
    # Рендерим фон элемента
    render_item_background(context, item, y, state)
    
    # Рендерим иконку
    render_item_icon(context, item, level, y)
    
    # Рендерим текст
    render_item_text(context, item, level, y)
    
    # НЕ рендерим expander - убираем его полностью
  end
  
  def render_item_background(context, item, y, state)
    if item == state.selected_item
      # Выделение
      context.draw_rectangle(1, y, context.width - 2, @theme.item_height, @theme.selection_color)
    elsif item == state.hovered_item
      # Hover эффект
      context.draw_rectangle(1, y, context.width - 2, @theme.item_height, @theme.hover_color)
    else
      # Обычный фон
      context.draw_rectangle(0, y, context.width, @theme.item_height, @theme.item_background_color)
    end
  end
  
  def render_item_icon(context, item, level, y)
    icon_x = @theme.icon_x(level)
    icon_y = @theme.icon_y(y)
    
    case item.type
    when :parent
      # Стрелка вверх для родительской директории
      context.draw_up_arrow(icon_x, icon_y, @theme.parent_color)
    when :directory
      # Иконка папки
      context.draw_folder_icon(icon_x, icon_y, @theme.folder_color)
    when :file
      # Иконка файла
      context.draw_file_icon(icon_x, icon_y, @theme.icon_color)
    end
  end
  
  def render_expander(context, item, level, y, state)
    exp_x = @theme.expander_x(level)
    exp_y = @theme.expander_center_y(y)
    
    if state.expanded?(item)
      # Рендерим минус (collapsed)
      context.draw_line(exp_x - 3, exp_y, exp_x + 3, exp_y, @theme.expander_color)
    else
      # Рендерим плюс (expanded)
      context.draw_line(exp_x - 3, exp_y, exp_x + 3, exp_y, @theme.expander_color)
      context.draw_line(exp_x, exp_y - 3, exp_x, exp_y + 3, @theme.expander_color)
    end
  end
  
  def render_item_text(context, item, level, y)
    text_x = @theme.text_x(level)
    text_y = @theme.text_y(y)
    
    # Обрезаем имя если оно слишком длинное
    display_name = truncate_name(item.name, 30)
    
    context.draw_text(text_x, text_y, display_name, @theme.font_size, @theme.text_color)
  end
  
  def truncate_name(name, max_length = 30)
    return name if name.length <= max_length
    
    # Показываем начало и конец имени
    start_length = (max_length - 3) / 2
    end_length = max_length - 3 - start_length
    "#{name[0, start_length]}...#{name[-end_length, end_length]}"
  end
  
  def invalidate_layout
    @layout.invalidate
  end
  
  def item_at_position(x, y, scroll_offset)
    @layout.item_at_position(x, y, scroll_offset)
  end
  
  def get_total_height
    @layout.total_height
  end
  
  protected
  
  def can_expand?(item)
    item.respond_to?(:can_expand?) && item.can_expand?
  end
end 