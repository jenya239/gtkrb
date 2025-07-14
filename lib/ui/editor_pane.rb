require 'gtk3'
require_relative 'code_editor'

class EditorPane
  attr_reader :pane_id

  def initialize
    @pane_id = "pane_#{object_id}"
    @box = Gtk::Box.new(:vertical, 0)
    @current_editor = CodeEditor.new
    @current_file = nil
    @on_focus_callback = nil
    @on_modified_callback = nil
    @on_button_callback = nil
    
    setup_ui
  end

  def widget
    @box
  end

  def load_file(file_path)
    @current_file = file_path
    @current_editor.load_file(file_path)
    update_file_label
    emit_focus
  end

  def get_current_editor
    @current_editor
  end

  def get_current_file
    @current_file
  end

  def has_file?
    @current_file != nil
  end

  def on_focus(&block)
    @on_focus_callback = block
  end

  def on_modified(&block)
    @on_modified_callback = block
  end

  def on_button(&block)
    @on_button_callback = block
  end

  private

  def setup_ui
    # Панель с информацией о файле
    @file_info_box = Gtk::Box.new(:horizontal, 8)
    @file_info_box.set_margin_left(8)
    @file_info_box.set_margin_right(8)
    @file_info_box.set_margin_top(3)
    @file_info_box.set_margin_bottom(3)
    
    # Путь файла
    @file_label = Gtk::Label.new("No file opened")
    @file_label.set_xalign(0.0)
    @file_label.set_ellipsize(:middle)
    @file_label.override_font(Pango::FontDescription.new('Monospace 8'))
    @file_info_box.pack_start(@file_label, expand: true, fill: true, padding: 0)
    
    # Маленькая кнопочка-иконка
    @test_button_label = Gtk::Label.new("■")
    @test_button_label.set_size_request(12, 12)
    @test_button_label.override_font(Pango::FontDescription.new('Sans 8'))
    @test_button_label.override_color(:normal, Gdk::RGBA::new(0.6, 0.6, 0.6, 1.0))
    
    @test_button = Gtk::EventBox.new
    @test_button.add(@test_button_label)
    @test_button.set_size_request(12, 12)
    @test_button.signal_connect('button-press-event') do |widget, event|
      @on_button_callback.call(self) if @on_button_callback
      true
    end
    
    # Эффект hover
    @test_button.signal_connect('enter-notify-event') do
      @test_button_label.override_color(:normal, Gdk::RGBA::new(0.9, 0.9, 0.9, 1.0))
    end
    
    @test_button.signal_connect('leave-notify-event') do
      @test_button_label.override_color(:normal, Gdk::RGBA::new(0.6, 0.6, 0.6, 1.0))
    end
    
    @file_info_box.pack_end(@test_button, expand: false, fill: false, padding: 2)
    
    # Стилизация панели информации
    style_file_info_box
    
    # Добавляем компоненты в основной контейнер
    @box.pack_start(@file_info_box, expand: false, fill: true, padding: 0)
    @box.pack_start(@current_editor.widget, expand: true, fill: true, padding: 0)
    
    # Подключаем обработчики
    @current_editor.on_modified { emit_modified }
    
    # Обработчик клика для фокуса
    @box.signal_connect('button-press-event') do |widget, event|
      emit_focus
      false
    end
    
    @current_editor.widget.signal_connect('button-press-event') do |widget, event|
      emit_focus
      false
    end
  end

  def style_file_info_box
    # Простая стилизация без CSS
    @file_info_box.override_background_color(:normal, Gdk::RGBA::new(0.18, 0.18, 0.18, 1.0))
    @file_label.override_color(:normal, Gdk::RGBA::new(0.9, 0.9, 0.9, 1.0))
  end

  def update_file_label
    if @current_file
      # Показываем только имя файла с расширением
      filename = File.basename(@current_file)
      @file_label.text = filename
      @file_label.set_tooltip_text(@current_file)
    else
      @file_label.text = "No file opened"
      @file_label.set_tooltip_text("")
    end
  end

  def emit_focus
    @on_focus_callback.call(self) if @on_focus_callback
  end

  def emit_modified
    @on_modified_callback.call if @on_modified_callback
  end
end 