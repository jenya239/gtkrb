#!/usr/bin/env ruby

require 'gtk4'
require 'cairo'

# Полностью кастомный компонент дерева файлов
class CustomTreeWidget < Gtk::Widget
  type_register

  class << self
    def init
      set_template resource: '/org/example/custom-tree.ui'
      bind_template_child 'scroll_area'
    end
  end

  def initialize
    super
    @items = []
    @selected_index = -1
    @scroll_offset = 0
    @item_height = 25
    @visible_items = 0
    
    setup_widget
    load_current_directory
  end

  private

  def setup_widget
    # Создаем область прокрутки
    @scroll_area = Gtk::ScrolledWindow.new
    @scroll_area.set_policy(:automatic, :automatic)
    
    # Создаем виджет для отрисовки
    @drawing_area = Gtk::DrawingArea.new
    @drawing_area.set_draw_func(method(:draw_tree))
    @drawing_area.set_size_request(250, 400)
    
    # Подключаем события мыши
    @drawing_area.add_controller(create_mouse_controller)
    
    # Подключаем события клавиатуры
    @drawing_area.add_controller(create_key_controller)
    
    @scroll_area.set_child(@drawing_area)
    self.set_child(@scroll_area)
  end

  def create_mouse_controller
    controller = Gtk::GestureClick.new
    controller.signal_connect("pressed") do |gesture, n_press, x, y|
      handle_mouse_click(x, y)
    end
    controller
  end

  def create_key_controller
    controller = Gtk::EventControllerKey.new
    controller.signal_connect("key-pressed") do |event_controller, keyval, keycode, state|
      handle_key_press(keyval, state)
    end
    controller
  end

  def handle_mouse_click(x, y)
    # Вычисляем индекс элемента под курсором
    adjusted_y = y + @scroll_offset
    index = (adjusted_y / @item_height).to_i
    
    if index >= 0 && index < @items.length
      @selected_index = index
      @drawing_area.queue_draw
      notify_selection_changed
    end
  end

  def handle_key_press(keyval, state)
    case keyval
    when Gdk::Keyval::KEY_Up
      @selected_index = [@selected_index - 1, 0].max
      @drawing_area.queue_draw
      notify_selection_changed
    when Gdk::Keyval::KEY_Down
      @selected_index = [@selected_index + 1, @items.length - 1].min
      @drawing_area.queue_draw
      notify_selection_changed
    when Gdk::Keyval::KEY_Return, Gdk::Keyval::KEY_KP_Enter
      activate_selected_item
    end
  end

  def draw_tree(widget, cr, width, height)
    # Очищаем фон
    cr.set_source_rgb(0.95, 0.95, 0.95)
    cr.paint
    
    # Вычисляем видимые элементы
    @visible_items = (height / @item_height).ceil
    
    # Отрисовываем элементы
    @items.each_with_index do |item, index|
      y = index * @item_height - @scroll_offset
      next if y + @item_height < 0 || y > height
      
      draw_item(cr, item, y, width, index == @selected_index)
    end
  end

  def draw_item(cr, item, y, width, selected)
    # Фон элемента
    if selected
      cr.set_source_rgb(0.2, 0.5, 0.9)
    else
      cr.set_source_rgb(1.0, 1.0, 1.0)
    end
    cr.rectangle(0, y, width, @item_height)
    cr.fill
    
    # Граница
    cr.set_source_rgb(0.8, 0.8, 0.8)
    cr.set_line_width(1)
    cr.rectangle(0, y, width, @item_height)
    cr.stroke
    
    # Текст
    cr.set_source_rgb(0.0, 0.0, 0.0)
    cr.select_font_face("Sans", Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
    cr.set_font_size(12)
    
    # Иконка в зависимости от типа
    icon = item[:type] == :directory ? "📁" : "📄"
    if item[:name] == ".."
      icon = "⬆️"
    end
    
    # Отрисовка иконки и текста
    cr.move_to(10, y + 15)
    cr.show_text(icon)
    
    cr.move_to(35, y + 15)
    cr.show_text(item[:name])
  end

  def load_current_directory
    @current_path = Dir.pwd
    refresh_items
  end

  def refresh_items
    @items.clear
    
    # Добавляем ".." если не в корне
    parent_path = File.dirname(@current_path)
    if parent_path != @current_path
      @items << { name: "..", path: "..", type: :parent }
    end
    
    # Добавляем текущую директорию
    @items << { name: File.basename(@current_path), path: @current_path, type: :directory }
    
    # Добавляем содержимое директории
    Dir.children(@current_path).sort.each do |entry|
      next if entry.start_with?('.')
      full_path = File.join(@current_path, entry)
      
      if File.directory?(full_path)
        @items << { name: entry, path: full_path, type: :directory }
      else
        @items << { name: entry, path: full_path, type: :file }
      end
    end
    
    @selected_index = -1
    @scroll_offset = 0
    @drawing_area.queue_draw
  end

  def activate_selected_item
    return if @selected_index < 0 || @selected_index >= @items.length
    
    item = @items[@selected_index]
    
    case item[:type]
    when :parent
      go_to_parent
    when :directory
      @current_path = item[:path]
      refresh_items
    when :file
      puts "Opening file: #{item[:path]}"
      # TODO: Открыть файл
    end
  end

  def go_to_parent
    parent_path = File.dirname(@current_path)
    return if parent_path == @current_path
    
    @current_path = parent_path
    refresh_items
  end

  def notify_selection_changed
    return if @selected_index < 0 || @selected_index >= @items.length
    
    item = @items[@selected_index]
    signal_emit("selection-changed", item[:path])
  end

  # Публичные методы
  def get_selected_path
    return nil if @selected_index < 0 || @selected_index >= @items.length
    @items[@selected_index][:path]
  end

  def refresh
    refresh_items
  end
end

# Регистрируем сигнал
CustomTreeWidget.signal_new("selection-changed", GObject::SIGNAL_RUN_LAST, nil, [String])

# Тестовое приложение
app = Gtk::Application.new("org.example.custom-tree", :default_flags)

app.signal_connect "activate" do |application|
  win = Gtk::ApplicationWindow.new(application)
  win.set_title("Custom Tree Widget")
  win.set_default_size(400, 500)
  
  # Создаем кастомный виджет
  tree = CustomTreeWidget.new
  
  # Подключаем сигнал
  tree.signal_connect("selection-changed") do |widget, path|
    puts "Selected: #{path}"
  end
  
  # Кнопка обновления
  button = Gtk::Button.new(label: "Refresh")
  button.signal_connect("clicked") do
    tree.refresh
  end
  
  # Layout
  box = Gtk::Box.new(:vertical, 10)
  box.append(button)
  box.append(tree)
  
  win.set_child(box)
  win.present
end

puts "Starting Custom Tree Widget Test..."
app.run 