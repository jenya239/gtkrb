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
    @on_close_callback = nil
    @on_split_h_callback = nil
    @on_split_v_callback = nil
    @on_new_file_callback = nil
    @is_new_file = true
    @original_temp_file = nil
    @on_file_saved_callback = nil
    @on_history_callback = nil
    
    # История файлов для этого редактора
    @file_history = []
    @max_history_size = 20
    
    setup_ui
    setup_new_file
  end

  def widget
    @box
  end

  def load_file(file_path)
    @current_file = file_path
    @is_new_file = false
    @current_editor.load_file(file_path)
    
    # Добавляем файл в историю
    add_to_history(file_path)
    
    # Настраиваем обработку сохранения для существующего файла
    @current_editor.on_save_request { handle_save_request }
    
    update_file_label
    emit_focus
  end

  def load_new_file_content(content)
    @current_file = nil
    @is_new_file = true
    @current_editor.set_content(content)
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
    !@current_file.nil? && !@is_new_file
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

  def on_close(&block)
    @on_close_callback = block
  end

  def on_split_horizontal(&block)
    @on_split_h_callback = block
  end

  def on_split_vertical(&block)
    @on_split_v_callback = block
  end

  def on_new_file(&block)
    @on_new_file_callback = block
  end

  def on_save(&block)
    @on_save_callback = block
  end

  def on_file_saved(&block)
    @on_file_saved_callback = block
  end

  def on_history(&block)
    @on_history_callback = block
  end

  def get_file_history
    @file_history.dup
  end

  def add_to_history(file_path)
    return unless file_path && File.exist?(file_path)
    
    # Удаляем из истории если уже есть
    @file_history.delete(file_path)
    
    # Добавляем в начало
    @file_history.unshift(file_path)
    
    # Ограничиваем размер истории
    @file_history = @file_history.first(@max_history_size)
  end

  def clear_history
    @file_history.clear
  end

  def set_focus
    @current_editor.widget.grab_focus
  end

  def set_active_style
    @box.override_background_color(:normal, Gdk::RGBA::new(0.25, 0.25, 0.25, 1.0))
  end

  def set_inactive_style
    @box.override_background_color(:normal, Gdk::RGBA::new(0.2, 0.2, 0.2, 1.0))
  end

  def is_new_file?
    @is_new_file
  end

  def swap_editors_with(other_pane)
    # Сохраняем текущие редакторы и состояния
    my_editor = @current_editor
    my_file = @current_file
    my_is_new = @is_new_file
    
    other_editor = other_pane.get_current_editor
    other_file = other_pane.get_current_file
    other_is_new = other_pane.is_new_file?
    
    # Отключаем оба редактора от их родителей
    my_parent = my_editor.widget.parent
    my_parent.remove(my_editor.widget) if my_parent
    
    other_parent = other_editor.widget.parent
    other_parent.remove(other_editor.widget) if other_parent
    
    # Обмениваем редакторы
    @current_editor = other_editor
    @current_file = other_file
    @is_new_file = other_is_new
    
    other_pane.instance_variable_set(:@current_editor, my_editor)
    other_pane.instance_variable_set(:@current_file, my_file)
    other_pane.instance_variable_set(:@is_new_file, my_is_new)
    
    # Добавляем редакторы в новые контейнеры
    @box.pack_start(@current_editor.widget, expand: true, fill: true, padding: 0)
    other_pane.instance_variable_get(:@box).pack_start(my_editor.widget, expand: true, fill: true, padding: 0)
    
    # Обновляем отображение
    update_file_label
    other_pane.update_file_label
    
    # Подключаем обработчики
    @current_editor.on_modified { emit_modified }
    my_editor.on_modified { other_pane.emit_modified }
    
    # Показываем виджеты
    @current_editor.widget.show_all
    my_editor.widget.show_all
  end

  def get_swap_data
    editor = @current_editor
    result = {
      file_path: @current_file,
      content: editor.get_content,
      cursor_position: editor.get_cursor_position,
      language: editor.instance_variable_get(:@language)
    }
    result
  end

  def apply_swap_data(data)
    editor = @current_editor
    
    # Сохраняем старый файл
    old_file = @current_file
    
    # Применяем новые данные
    @current_file = data[:file_path]
    @is_new_file = false
    
    editor.set_content(data[:content])
    editor.set_cursor_position(data[:cursor_position]) if data[:cursor_position]
    
    # Настраиваем обработку сохранения
    @current_editor.on_save_request { handle_save_request }
    
    # Обновляем интерфейс
    update_file_label
    
    result
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
    
    # Контейнер для кнопок
    @buttons_box = Gtk::Box.new(:horizontal, 2)
    
    # Кнопки действий
    create_button("⊞", :new_file)     # Новый файл
    create_button("❙", :split_h)      # Горизонтальное разделение
    create_button("═", :split_v)      # Вертикальное разделение
    create_button("⏷", :history)      # История файлов
    create_button("✗", :close)        # Закрыть
    
    @buttons_box.pack_start(@test_button, expand: false, fill: false, padding: 0)
    @file_info_box.pack_end(@buttons_box, expand: false, fill: false, padding: 2)
    
    # Стилизация панели информации
    style_file_info_box
    
    # Добавляем компоненты в основной контейнер
    @box.pack_start(@file_info_box, expand: false, fill: true, padding: 0)
    @box.pack_start(@current_editor.widget, expand: true, fill: true, padding: 0)
    
    # Подключаем обработчики
    @current_editor.on_modified do
      emit_modified
      update_file_label
    end
    
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

  public
  
  def update_file_label
    puts "update_file_label: file=#{@current_file}, is_new=#{@is_new_file}, modified=#{@current_editor.modified?}"
    
    if @current_file && !@is_new_file
      # Показываем полный путь с троеточием если не влезает
      display_path = truncate_path(@current_file, 50)
      
      # Добавляем индикатор модификации
      if @current_editor.modified?
        display_path += " *"
      end
      
      @file_label.text = display_path
      @file_label.set_tooltip_text(@current_file)
      puts "Setting label to: #{display_path}"
    else
      label_text = @is_new_file ? "Untitled" : "No file opened"
      
      # Добавляем индикатор модификации для новых файлов
      if @is_new_file && @current_editor.modified?
        label_text += " *"
      end
      
      @file_label.text = label_text
      @file_label.set_tooltip_text("")
      puts "Setting label to: #{label_text}"
    end
    
    # Принудительно обновляем виджет
    @file_label.queue_draw
    @file_info_box.queue_draw
  end

  private

  def emit_focus
    @on_focus_callback.call(self) if @on_focus_callback
  end

  public
  
  def emit_modified
    @on_modified_callback.call if @on_modified_callback
  end

  private

  def setup_new_file
    # Создаем временный файл
    @original_temp_file = "/tmp/untitled_#{Time.now.to_i}.txt"
    File.write(@original_temp_file, "")
    
    # Настраиваем обработку сохранения для нового файла
    @current_editor.on_save_request { handle_save_request }
  end

  def handle_save_request
    if @is_new_file
      request_save_as
    else
      request_save
    end
  end

  def request_save
    return unless @current_file
    
    begin
      content = @current_editor.get_content
      File.write(@current_file, content)
      @current_editor.reset_modified
      update_file_label
      @on_file_saved_callback.call(@current_file) if @on_file_saved_callback
      puts "File saved: #{@current_file}"
    rescue => e
      puts "Error saving file: #{e.message}"
    end
  end

  def request_save_as
    @on_save_callback.call(self) if @on_save_callback
  end

  public
  
  def mark_as_saved(file_path)
    @current_file = file_path
    @is_new_file = false
    
    # Удаляем временный файл
    if @original_temp_file && File.exist?(@original_temp_file)
      File.delete(@original_temp_file)
      @original_temp_file = nil
    end
    
    # Настраиваем обработку сохранения для существующего файла
    @current_editor.on_save_request { handle_save_request }
    
    # Обновляем отображение
    update_file_label
    
    # Уведомляем о сохранении для обновления панели файлов
    @on_file_saved_callback.call(file_path) if @on_file_saved_callback
  end

  def create_button(icon, action)
    button_label = Gtk::Label.new(icon)
    button_label.set_size_request(12, 12)
    button_label.override_font(Pango::FontDescription.new('Sans 8'))
    button_label.override_color(:normal, Gdk::RGBA::new(0.6, 0.6, 0.6, 1.0))

    button = Gtk::EventBox.new
    button.add(button_label)
    button.set_size_request(12, 12)
    
    # Сохраняем action для поиска
    button.instance_variable_set(:@action, action)
    
    button.signal_connect('button-press-event') do |widget, event|
      case action
      when :new_file
        @on_new_file_callback.call(self) if @on_new_file_callback
      when :split_h
        @on_split_h_callback.call(self) if @on_split_h_callback
      when :split_v
        @on_split_v_callback.call(self) if @on_split_v_callback
      when :history
        @on_history_callback.call(self) if @on_history_callback
      when :close
        @on_close_callback.call(self) if @on_close_callback
      end
      true
    end

    # Эффект hover
    button.signal_connect('enter-notify-event') do
      button_label.override_color(:normal, Gdk::RGBA::new(0.9, 0.9, 0.9, 1.0))
    end

    button.signal_connect('leave-notify-event') do
      button_label.override_color(:normal, Gdk::RGBA::new(0.6, 0.6, 0.6, 1.0))
    end

    @buttons_box.pack_start(button, expand: false, fill: false, padding: 0)
  end

  private

  def truncate_path(path, max_length)
    return path if path.length <= max_length
    
    # Оставляем начало и конец пути, добавляем ... посередине
    start_length = max_length / 2 - 2
    end_length = max_length - start_length - 3
    
    path[0...start_length] + "..." + path[-end_length..-1]
  end
end 