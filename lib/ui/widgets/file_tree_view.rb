#!/usr/bin/env ruby

require 'gtk4'
require 'cairo'
require 'gdk_pixbuf2'
require_relative 'tree_data_provider'

# Конфигурация внешнего вида
class TreeViewTheme
  ICON_FOLDER = GdkPixbuf::Pixbuf.new(file: "icons/folder.png", width: 14, height: 14)
  ICON_FILE   = GdkPixbuf::Pixbuf.new(file: "icons/file.png",   width: 14, height: 14)
  ICON_UP     = GdkPixbuf::Pixbuf.new(file: "icons/up.png",     width: 14, height: 14)
  
  COLORS = {
    background: [0xfdf6e3, 0.97],
    foreground: [0x657b83, 0.0],
    selection: [0xb58900, 0.15],
    directory: [0x268bd2, 0.0],
    file: [0x586e75, 0.0],
    parent: [0x859900, 0.0]
  }
  
  def self.rgb(hex, alpha=0.0)
    r = ((hex >> 16) & 0xff) / 255.0
    g = ((hex >> 8) & 0xff) / 255.0
    b = (hex & 0xff) / 255.0
    [r, g, b, 1.0-alpha]
  end
end

# Модель данных дерева
class TreeItem
  attr_accessor :name, :path, :type, :level, :children, :expanded
  
  def initialize(name:, path:, type:, level: 0, children: nil)
    @name = name
    @path = path
    @type = type
    @level = level
    @children = children
    @expanded = false
  end
  
  def directory?
    [:directory, :current].include?(@type)
  end
  
  def file?
    @type == :file
  end
  
  def parent?
    @type == :parent
  end
end

# Рендерер элементов дерева
class TreeItemRenderer
  def initialize(theme = TreeViewTheme)
    @theme = theme
  end
  
  def render(cr, item, x, y, width, height, selected, hovered)
    draw_background(cr, x, y, width, height, selected, hovered)
    draw_icon(cr, item, x, y)
    draw_expander(cr, item, x, y) if item.directory?
    draw_text(cr, item, x, y)
  end
  
  private
  
  def draw_background(cr, x, y, width, height, selected, hovered)
    if selected
      cr.set_source_rgba(*@theme.rgb(*@theme::COLORS[:selection]))
    elsif hovered
      cr.set_source_rgba(0.87, 0.91, 0.95, 0.7)
    else
      cr.set_source_rgba(*@theme.rgb(*@theme::COLORS[:background]))
    end
    cr.rectangle(x, y, width, height)
    cr.fill
  end
  
  def draw_icon(cr, item, x, y)
    icon = case item.type
           when :parent then @theme::ICON_UP
           when :directory, :current then @theme::ICON_FOLDER
           else @theme::ICON_FILE
           end
    
    cr.save
    cr.translate(x + 4, y + 1)
    cr.set_source_pixbuf(icon, 0, 0)
    cr.paint
    cr.restore
  end
  
  def draw_expander(cr, item, x, y)
    return unless item.children
    
    cr.set_source_rgba(0.5, 0.5, 0.5, 0.7)
    cr.set_line_width(1.5)
    cx = x + 16
    cy = y + 8
    
    if item.expanded
      cr.move_to(cx - 3, cy - 1)
      cr.line_to(cx, cy + 2)
      cr.line_to(cx + 3, cy - 1)
    else
      cr.move_to(cx - 1, cy - 3)
      cr.line_to(cx + 2, cy)
      cr.line_to(cx - 1, cy + 3)
    end
    cr.stroke
  end
  
  def draw_text(cr, item, x, y)
    color = case item.type
            when :parent then @theme::COLORS[:parent]
            when :directory, :current then @theme::COLORS[:directory]
            else @theme::COLORS[:file]
            end
    
    cr.set_source_rgba(*@theme.rgb(*color))
    cr.select_font_face("Fira Mono", Cairo::FONT_SLANT_NORMAL, 
                       item.type == :current ? Cairo::FONT_WEIGHT_BOLD : Cairo::FONT_WEIGHT_NORMAL)
    cr.set_font_size(10)
    cr.move_to(x + 22, y + 12)
    cr.show_text(item.name)
  end
end

# Контроллер событий
class TreeEventController
  def initialize(tree_view)
    @tree_view = tree_view
    setup_events
  end
  
  private
  
  def setup_events
    setup_mouse_events
    setup_keyboard_events
  end
  
  def setup_mouse_events
    click = Gtk::GestureClick.new
    click.signal_connect("pressed") { |_, n_press, x, y| handle_click(n_press, x, y) }
    @tree_view.add_controller(click)
    
    motion = Gtk::EventControllerMotion.new
    motion.signal_connect("motion") { |_, x, y| handle_motion(x, y) }
    @tree_view.add_controller(motion)
    
    leave = Gtk::EventControllerMotion.new
    leave.signal_connect("leave") { |_| handle_leave }
    @tree_view.add_controller(leave)
  end
  
  def setup_keyboard_events
    key = Gtk::EventControllerKey.new
    key.signal_connect("key-pressed") { |_, k, _, _| handle_key(k) }
    @tree_view.add_controller(key)
  end
  
  def handle_click(n_press, x, y)
    idx = @tree_view.index_at_position(x, y)
    return unless idx
    
    @tree_view.select_item(idx)
    item = @tree_view.item_at_index(idx)
    
    case item.type
    when :directory
      n_press == 1 ? @tree_view.toggle_expand(item) : @tree_view.enter_directory(item)
    when :file
      @tree_view.open_file(item) if n_press == 1
    when :parent
      @tree_view.go_up if n_press == 2
    end
  end
  
  def handle_motion(x, y)
    idx = @tree_view.index_at_position(x, y)
    @tree_view.set_hover_index(idx)
  end
  
  def handle_leave
    @tree_view.set_hover_index(-1)
  end
  
  def handle_key(keyval)
    case keyval
    when Gdk::Keyval::KEY_Up
      @tree_view.select_previous
    when Gdk::Keyval::KEY_Down
      @tree_view.select_next
    when Gdk::Keyval::KEY_Return
      @tree_view.activate_selected
    end
  end
end

# Основной компонент дерева файлов
class FileTreeView < Gtk::ScrolledWindow
  attr_reader :selected_index, :hover_index
  
  def initialize(data_provider = nil)
    super()
    set_policy(:never, :automatic)
    
    @area = Gtk::DrawingArea.new
    @area.set_hexpand(true)
    @area.set_vexpand(true)
    set_child(@area)
    
    @selected_index = -1
    @hover_index = -1
    @item_height = 16
    @items = []
    @expanded_paths = {}
    
    @data_provider = data_provider || FileSystemDataProvider.new
    @renderer = TreeItemRenderer.new
    @event_controller = TreeEventController.new(self)
    
    @area.set_draw_func { |_, cr, w, h| draw(cr, w, h) }
  end
  
  def load_directory(path)
    @current_path = path
    @expanded_paths = {}
    refresh
  end
  
  def set_data_provider(provider)
    @data_provider = provider
    refresh
  end
  
  def refresh
    @items = build_tree_items(@current_path)
    @selected_index = -1
    update_content_height
    @area.queue_draw
  end
  
  def select_item(index)
    return unless index.between?(0, @items.size - 1)
    @selected_index = index
    @area.queue_draw
  end
  
  def set_hover_index(index)
    @hover_index = index
    @area.queue_draw
  end
  
  def select_previous
    @selected_index = [@selected_index - 1, 0].max
    @area.queue_draw
  end
  
  def select_next
    @selected_index = [@selected_index + 1, @items.size - 1].min
    @area.queue_draw
  end
  
  def activate_selected
    return if @selected_index < 0
    item = @items[@selected_index]
    
    case item.type
    when :directory then enter_directory(item)
    when :file then open_file(item)
    when :parent then go_up
    end
  end
  
  def toggle_expand(item)
    @expanded_paths[item.path] = !@expanded_paths[item.path]
    refresh
  end
  
  def enter_directory(item)
    @current_path = item.path
    @expanded_paths = {}
    refresh
  end
  
  def go_up
    parent = File.dirname(@current_path)
    return if parent == @current_path
    @current_path = parent
    @expanded_paths = {}
    refresh
  end
  
  def open_file(item)
    # Событие будет обработано внешним кодом через callback
    @file_selected_callback&.call(item.path)
  end
  
  def on_file_selected(&block)
    @file_selected_callback = block
  end
  
  def index_at_position(x, y)
    idx = ((y + vscroll) / @item_height).to_i
    idx.between?(0, @items.size - 1) ? idx : nil
  end
  
  def item_at_index(index)
    @items[index] if index.between?(0, @items.size - 1)
  end
  
  def selected_item
    @items[@selected_index] if @selected_index >= 0
  end
  
  private
  
  def vscroll
    vadjustment ? vadjustment.value : 0
  end
  
  def draw(cr, width, height)
    cr.set_source_rgba(*TreeViewTheme.rgb(*TreeViewTheme::COLORS[:background]))
    cr.rectangle(0, 0, width, height)
    cr.fill
    
    y0 = vscroll
    @items.each_with_index do |item, i|
      y = i * @item_height - y0
      next if y + @item_height < 0 || y > height
      
      x_offset = item.level * 12
      x_offset = 0 if [:current, :parent].include?(item.type)
      
      @renderer.render(cr, item, x_offset, y, width - x_offset, @item_height, 
                      i == @selected_index, i == @hover_index)
    end
  end
  
  def build_tree_items(path)
    @data_provider.get_items(path)
  end
  
  def update_content_height
    @area.set_height_request([@items.size * @item_height, 1].max)
  end
end

# Сигнал будет обрабатываться через callback 