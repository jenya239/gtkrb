#!/usr/bin/env ruby

require 'gtk3'
require 'cairo'
require 'set'

ICON_FOLDER = GdkPixbuf::Pixbuf.new(file: File.expand_path('../../../../icons/folder.png', __FILE__), width: 12, height: 12)
ICON_FILE = GdkPixbuf::Pixbuf.new(file: File.expand_path('../../../../icons/file.png', __FILE__), width: 12, height: 12)
ICON_UP = GdkPixbuf::Pixbuf.new(file: File.expand_path('../../../../icons/up.png', __FILE__), width: 12, height: 12)

# Базовый интерфейс для данных дерева
class TreeDataSource
  def get_root_items
    raise NotImplementedError
  end
  
  def get_children(parent_item)
    raise NotImplementedError
  end
  
  def can_expand?(item)
    raise NotImplementedError
  end
end

# Модель состояния дерева
class TreeState
  attr_accessor :expanded_items, :selected_item, :hovered_item, :scroll_offset
  
  def initialize
    @expanded_items = Set.new
    @selected_item = nil
    @hovered_item = nil
    @scroll_offset = 0
  end
  
  def expanded?(item)
    @expanded_items.include?(item)
  end
  
  def toggle_expanded(item)
    if expanded?(item)
      @expanded_items.delete(item)
    else
      @expanded_items.add(item)
    end
  end
end

# Кэш layout для оптимизации
class TreeLayoutCache
  attr_accessor :rows, :total_height, :dirty
  
  def initialize
    @rows = []
    @total_height = 0
    @dirty = true
  end
  
  def invalidate
    @dirty = true
  end
  
  def needs_update?
    @dirty
  end
end

# Виртуализированный рендерер
class VirtualTreeRenderer
  def initialize(theme)
    @theme = theme
    @item_height = 15
  end
  
  def render_cairo(cr, bounds, layout_cache, state, data_source)
    # Background
    cr.set_source_rgba(*@theme.background_color)
    cr.paint
    
    # Render only visible rows
    visible_range = calculate_visible_range(bounds.height, state.scroll_offset)
    visible_rows = layout_cache.rows[visible_range[0]..visible_range[1]] || []
    
    visible_rows.each_with_index do |row, idx|
      y = (visible_range[0] + idx) * @item_height - state.scroll_offset
      render_item(cr, row, 0, y, bounds.width, @item_height, state, data_source)
    end
  end
  
  def update_layout(layout_cache, data_source, state)
    return unless layout_cache.needs_update?
    
    layout_cache.rows = flatten_tree(data_source)
    layout_cache.total_height = layout_cache.rows.size * @item_height
    layout_cache.dirty = false
  end
  
  private
  
  def calculate_visible_range(height, scroll_offset)
    start_idx = (scroll_offset / @item_height).floor
    end_idx = ((scroll_offset + height) / @item_height).ceil
    [start_idx, end_idx]
  end
  
  def flatten_tree(data_source)
    # Используем готовый метод из FileTreeManager
    data_source.get_flat_tree
  end
  
  def render_item(cr, item_data, x, y, width, height, state, data_source)
    item, level = item_data
    indent = level * 14

    # Background - исправляем проблему с выделением
    if item == state.selected_item
      cr.set_source_rgb(0.8, 0.9, 1.0)
    elsif item == state.hovered_item
      cr.set_source_rgb(0.95, 0.95, 0.95)
    else
      cr.set_source_rgb(1, 1, 1)
    end
    cr.rectangle(x, y, width, height)
    cr.fill

    # Иконка
    icon_x = x + indent + 2
    icon_y = y + 2
    if item.type == :parent
      cr.set_source_pixbuf(ICON_UP, icon_x, icon_y)
      cr.paint
    elsif item.type == :directory
      cr.set_source_pixbuf(ICON_FOLDER, icon_x, icon_y)
      cr.paint
    else
      cr.set_source_pixbuf(ICON_FILE, icon_x, icon_y)
      cr.paint
    end

    # Expander
    if data_source.can_expand?(item)
      exp_x = icon_x + 16
      exp_y = y + height/2
      cr.set_source_rgb(0.3, 0.3, 0.3)
      cr.set_line_width(1.0)
      if data_source.state.expanded?(item)
        # Минус для свернутого
        cr.move_to(exp_x - 3, exp_y)
        cr.line_to(exp_x + 3, exp_y)
      else
        # Плюс для раскрытого
        cr.move_to(exp_x, exp_y - 3)
        cr.line_to(exp_x, exp_y + 3)
        cr.stroke
        cr.move_to(exp_x - 3, exp_y)
        cr.line_to(exp_x + 3, exp_y)
      end
      cr.stroke
    end

    # Text
    text_x = icon_x + 18
    text_y = y + height - 3
    cr.set_source_rgb(0, 0, 0)
    cr.select_font_face("Sans", Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
    cr.set_font_size(9)
    cr.move_to(text_x, text_y)
    cr.show_text(item.to_s)
  end
  
  def render_icon(cr, item, x, y)
    cr.set_source_rgba(0.5, 0.5, 0.5, 1.0)
    cr.rectangle(x, y, 12, 12)
    cr.fill
  end
  
  def render_expander(cr, item, x, y, expanded)
    cr.set_source_rgba(0.3, 0.3, 0.3, 1.0)
    cr.set_line_width(1.0)
    
    if expanded
      cr.move_to(x - 3, y)
      cr.line_to(x + 3, y)
    else
      cr.move_to(x, y - 3)
      cr.line_to(x, y + 3)
    end
    cr.stroke
  end
  
  def render_text(cr, item, x, y)
    cr.set_source_rgba(*@theme.text_color)
    cr.select_font_face("Sans", Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
    cr.set_font_size(12)
    cr.move_to(x, y)
    cr.show_text(item.to_s)
  end
  
  def can_expand?(item)
    item.respond_to?(:children) && item.children&.any?
  end
end

# Контроллер событий для GTK3
class TreeEventController
  def initialize(tree_view)
    @tree_view = tree_view
    @last_click_time = 0
    @last_click_item = nil
    setup_events
  end

  private

  def setup_events
    setup_mouse_events
    setup_keyboard_events
  end

  def setup_mouse_events
    @tree_view.signal_connect("button-press-event") { |_, event| handle_click(event) }
    @tree_view.signal_connect("motion-notify-event") { |_, event| handle_motion(event) }
    @tree_view.signal_connect("key-press-event") { |_, event| handle_key(event) }
    @tree_view.add_events(Gdk::EventMask::BUTTON_PRESS_MASK |
                         Gdk::EventMask::POINTER_MOTION_MASK |
                         Gdk::EventMask::KEY_PRESS_MASK)
    # Скролл мышью
    @tree_view.signal_connect("scroll-event") { |_, event| handle_scroll(event) }
  end

  def setup_keyboard_events
    @tree_view.set_can_focus(true)
  end

  def handle_click(event)
    item = @tree_view.item_at_position(event.x, event.y)
    return false unless item
    
    now = Time.now.to_f
    double = (@last_click_item == item && now - @last_click_time < 0.35)
    @last_click_time = now
    @last_click_item = item
    
    @tree_view.select_item(item)
    if double
      @tree_view.activate_selected
    end
    # Убираем toggle_expand отсюда - пусть file_explorer управляет этим
    false
  end

  def handle_scroll(event)
    step = @tree_view.instance_variable_get(:@renderer).instance_variable_get(:@item_height) * 3
    if event.direction == Gdk::ScrollDirection::UP
      @tree_view.scroll_by(-step)
    elsif event.direction == Gdk::ScrollDirection::DOWN
      @tree_view.scroll_by(step)
    end
    false
  end

  def handle_motion(event)
    item = @tree_view.item_at_position(event.x, event.y)
    @tree_view.set_hovered_item(item)
    false
  end

  def handle_key(event)
    case event.keyval
    when Gdk::Keyval::KEY_Up
      @tree_view.select_previous
    when Gdk::Keyval::KEY_Down
      @tree_view.select_next
    when Gdk::Keyval::KEY_Return
      @tree_view.activate_selected
    end
    false
  end
end

# Основной компонент дерева для GTK3
class TreeView < Gtk::DrawingArea
  attr_reader :state
  
  def initialize(data_source = nil)
    super()
    set_hexpand(true)
    set_vexpand(true)
    set_size_request(-1, 200)
    
    @data_source = data_source
    @state = TreeState.new
    @layout_cache = TreeLayoutCache.new
    @renderer = VirtualTreeRenderer.new(TreeTheme.new)
    @event_controller = TreeEventController.new(self)
    @item_selected_callback = nil
    @item_activated_callback = nil
    @item_height = 20
    @width = 0
    @height = 0
    
    # GTK3 использует signal_connect для draw
    signal_connect("draw") { |_, cr| draw(cr) }
  end
  
  def set_renderer(renderer)
    @renderer = renderer
    @layout_cache.invalidate
    queue_draw
  end
  
  public
  
  def set_data_source(data_source)
    @data_source = data_source
    @layout_cache.invalidate
    queue_draw
  end
  
  def refresh
    @state.selected_item = nil  # Убираем автоматическое выделение
    @state.hovered_item = nil
    @layout_cache.invalidate
    queue_draw
  end
  
  def select_item(item)
    @data_source.select_item(item)
    @state.selected_item = item
    @item_selected_callback&.call(item)
    # Убираем автоматический toggle_expand отсюда, чтобы избежать двойного вызова
    queue_draw
  end
  
  def set_hovered_item(item)
    return if @state.hovered_item == item
    @state.hovered_item = item
    queue_draw
  end
  
  def toggle_expand(item)
    return unless can_expand?(item)
    @data_source.toggle_expand(item)
    @layout_cache.invalidate
    queue_draw
  end
  
  def can_expand?(item)
    @data_source&.can_expand?(item)
  end
  
  def scroll_by(delta)
    @state.scroll_offset = [@state.scroll_offset + delta, 0].max
    queue_draw
  end
  
  def select_previous
    items = @layout_cache.rows.map(&:first)
    return if items.empty?
    
    current_idx = items.index(@state.selected_item) || -1
    new_idx = [current_idx - 1, 0].max
    select_item(items[new_idx])
  end
  
  def select_next
    items = @layout_cache.rows.map(&:first)
    return if items.empty?
    
    current_idx = items.index(@state.selected_item) || -1
    new_idx = [current_idx + 1, items.size - 1].min
    select_item(items[new_idx])
  end
  
  def activate_selected
    return unless @state.selected_item
    @item_activated_callback&.call(@state.selected_item)
  end
  
  def item_at_position(x, y)
    idx = ((y + @state.scroll_offset) / @renderer.instance_variable_get(:@item_height)).to_i
    @layout_cache.rows[idx]&.first
  end
  
  def on_item_selected(&block)
    @item_selected_callback = block
  end
  
  def on_item_activated(&block)
    @item_activated_callback = block
  end
  
  private
  
  def draw(cr)
    return false unless @data_source
    
    allocation = self.allocation
    @width = allocation.width
    @height = allocation.height
    
    # Обновляем layout если нужно
    @renderer.update_layout(@layout_cache, @data_source, @state)
    
    # Устанавливаем высоту для скролла
    set_size_request(-1, [@renderer.instance_variable_get(:@item_height) * @layout_cache.rows.size, 200].max)
    
    # Рендерим через Cairo context
    bounds = Gdk::Rectangle.new(0, 0, @width, @height)
    @renderer.render_cairo(cr, bounds, @layout_cache, @state, @data_source)
    
    false
  end
end

# Простая тема
class TreeTheme
  def background_color
    [0.95, 0.95, 0.95, 1.0]
  end
  
  def item_background_color
    [1.0, 1.0, 1.0, 1.0]
  end
  
  def selection_color
    [0.2, 0.5, 0.8, 0.3]
  end
  
  def hover_color
    [0.9, 0.9, 0.9, 1.0]
  end
  
  def text_color
    [0.2, 0.2, 0.2, 1.0]
  end
end 