class TreeLayout
  attr_reader :theme, :cached_items, :total_height, :dirty
  
  def initialize(theme)
    @theme = theme
    @cached_items = []
    @total_height = 0
    @dirty = true
  end
  
  def update_layout(items)
    @cached_items = items
    @total_height = items.size * @theme.item_height
    @dirty = false
  end
  
  def invalidate
    @dirty = true
  end
  
  def needs_update?
    @dirty
  end
  
  def get_visible_range(viewport_height, scroll_offset)
    return [0, 0] if @cached_items.empty?
    
    start_idx = (scroll_offset / @theme.item_height).floor
    end_idx = ((scroll_offset + viewport_height) / @theme.item_height).ceil
    
    start_idx = [start_idx, 0].max
    end_idx = [end_idx, @cached_items.size - 1].min
    
    [start_idx, end_idx]
  end
  
  def get_visible_items(viewport_height, scroll_offset)
    start_idx, end_idx = get_visible_range(viewport_height, scroll_offset)
    return [] if start_idx > end_idx
    
    visible_items = []
    (@cached_items[start_idx..end_idx] || []).each_with_index do |item_data, idx|
      y_position = (start_idx + idx) * @theme.item_height - scroll_offset
      visible_items << [item_data, y_position]
    end
    
    visible_items
  end
  
  def item_at_position(x, y, scroll_offset)
    return nil if @cached_items.empty?
    
    adjusted_y = y + scroll_offset
    item_index = (adjusted_y / @theme.item_height).to_i
    
    return nil if item_index < 0 || item_index >= @cached_items.size
    
    @cached_items[item_index]&.first
  end
  
  def get_item_bounds(item, scroll_offset)
    item_index = @cached_items.index { |item_data, _| item_data.first == item }
    return nil unless item_index
    
    y = item_index * @theme.item_height - scroll_offset
    [0, y, Float::INFINITY, @theme.item_height]
  end
  
  def scroll_to_item(item, viewport_height)
    item_index = @cached_items.index { |item_data, _| item_data.first == item }
    return 0 unless item_index
    
    item_y = item_index * @theme.item_height
    
    # Если элемент уже видим, не скроллим
    if item_y >= 0 && item_y + @theme.item_height <= viewport_height
      return 0
    end
    
    # Скроллим так чтобы элемент был в центре
    center_offset = viewport_height / 2 - @theme.item_height / 2
    [item_y - center_offset, 0].max
  end
end 