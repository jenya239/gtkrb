require 'gtk3'
require_relative 'editor_pane'
require_relative 'split_container'

class EditorManager
  def initialize(container)
    @container = container
    @panes = []
    @active_pane = nil
    @grid_mode = false
    @on_modified_callbacks = []
    @on_file_saved_callback = nil
    
    setup_initial_pane
  end

  def widget
    @container.widget
  end

  def load_file(file_path)
    # Открываем файл в активном редакторе
    if @active_pane
      @active_pane.load_file(file_path)
    else
      create_pane.load_file(file_path)
    end
  end

  def split_horizontal
    if @grid_mode
      exit_grid_mode
    end
    
    if @active_pane
      new_pane = create_pane
      @container.split_horizontal(@active_pane, new_pane)
      @active_pane = new_pane
      @active_pane.set_focus
    end
  end

  def split_vertical
    if @grid_mode
      exit_grid_mode
    end
    
    if @active_pane
      new_pane = create_pane
      @container.split_vertical(@active_pane, new_pane)
      @active_pane = new_pane
      @active_pane.set_focus
    end
  end

  def close_active_pane
    close_pane(@active_pane) if @active_pane
  end

  def on_modified(&block)
    @on_modified_callbacks << block
  end

  def on_file_saved(&block)
    @on_file_saved_callback = block
  end

  def get_active_pane
    @active_pane
  end

  def get_all_panes
    @panes.dup
  end

  def get_active_file
    @active_pane ? @active_pane.get_current_file : nil
  end

  def load_multiple_files(file_paths)
    return if file_paths.empty?
    
    # Очищаем существующие панели и контейнер
    @panes.clear
    @container.set_root_container(Gtk::Box.new(:vertical, 0))
    
    # Создаем grid-сетку
    create_grid_from_files(file_paths)
    
    # Устанавливаем первую панель как активную
    @active_pane = @panes.first
    @active_pane.set_focus if @active_pane
  end

  def load_directory(directory_path)
    return unless Dir.exist?(directory_path)
    
    # Получаем все файлы из директории
    files = Dir.glob(File.join(directory_path, "**/*")).select { |f| File.file?(f) }
    load_multiple_files(files)
  end

  def load_directories(directory_paths)
    all_files = []
    directory_paths.each do |dir|
      next unless Dir.exist?(dir)
      files = Dir.glob(File.join(dir, "**/*")).select { |f| File.file?(f) }
      all_files.concat(files)
    end
    load_multiple_files(all_files)
  end

  def grid_mode?
    @grid_mode || false
  end

  private

  def setup_initial_pane
    @active_pane = create_pane
    @container.set_root(@active_pane)
    @grid_mode = false
  end

  def create_pane
    pane = EditorPane.new
    @panes << pane
    
    # Убеждаемся что новая панель в правильном состоянии
    pane.ensure_correct_display_state
    
    pane.on_focus do |p| 
      # Обновляем активную панель
      old_active = @active_pane
      @active_pane = p
      
      # Обновляем стили
      @panes.each { |pane| pane.set_inactive_style }
      p.set_active_style
    end
    
    pane.on_modified { emit_modified }
    pane.on_button { |clicked_pane| swap_with_active(clicked_pane) }
    pane.on_close { |p| close_pane(p) }
    pane.on_split_horizontal { |p| split_pane_horizontal(p) }
    pane.on_split_vertical { |p| split_pane_vertical(p) }
    pane.on_new_file { |p| create_new_file(p) }
    pane.on_save { |p| show_save_dialog(p) }
    pane.on_file_saved { |file_path| @on_file_saved_callback.call(file_path) if @on_file_saved_callback }
    pane.on_history { |p| show_file_history(p) }
    
    pane
  end

  def split_pane_horizontal(pane)
    @active_pane = pane
    split_horizontal
  end

  def split_pane_vertical(pane)
    @active_pane = pane
    split_vertical
  end

  def create_new_file(pane)
    @active_pane = pane
    # Создаем временный файл
    temp_file = "/tmp/untitled_#{Time.now.to_i}.txt"
    File.write(temp_file, "")
    pane.load_file(temp_file)
    
    # Помечаем как новый файл для сохранения
    pane.instance_variable_set(:@is_new_file, true)
    pane.instance_variable_set(:@original_temp_file, temp_file)
    
    # Добавляем callback для сохранения
    pane.get_current_editor.on_save_request { show_save_dialog(pane) }
  end

  def show_save_dialog(pane)
    dialog = Gtk::FileChooserDialog.new(
      title: "Save File As",
      parent: nil,
      action: :save,
      buttons: [
        [Gtk::Stock::CANCEL, :cancel],
        [Gtk::Stock::SAVE, :accept]
      ]
    )
    
    dialog.set_current_name("untitled.txt")
    
    if dialog.run == :accept
      filename = dialog.filename
      current_content = pane.get_current_editor.get_content
      
      begin
        File.write(filename, current_content)
        pane.mark_as_saved(filename)
        emit_modified
      rescue => e
        puts "Error saving file: #{e.message}"
      end
    end
    
    dialog.destroy
  end

  def show_file_history(pane)
    history = pane.get_file_history
    return if history.empty?
    
    # Создаем компактный выпадающий список
    popup = create_compact_history_dropdown(pane, history)
    popup.show_all
  end

  def create_compact_history_dropdown(pane, history)
    # Создаем простое всплывающее окно
    popup = Gtk::Window.new(:popup)
    popup.set_type_hint(:dropdown_menu)
    popup.set_decorated(false)
    popup.set_resizable(false)
    popup.set_skip_taskbar_hint(true)
    popup.set_skip_pager_hint(true)
    # Убираем модальность для избежания проблем
    
    # Контейнер для списка
    list_container = Gtk::Box.new(:vertical, 0)
    
    # Флаг для предотвращения двойного destroy
    popup_destroyed = false
    
    # Безопасная функция уничтожения
    safe_destroy = proc do
      unless popup_destroyed
        popup_destroyed = true
        popup.destroy
      end
    end
    
    # Создаем элементы списка
    history.each_with_index do |file_path, index|
      # Создаем простую строку
      row = Gtk::Box.new(:horizontal, 2)
      row.set_size_request(-1, 18)
      
      # Темный фон
      row.override_background_color(:normal, Gdk::RGBA::new(0.15, 0.15, 0.15, 1.0))
      
      # Номер
      number_label = Gtk::Label.new("#{index + 1}")
      number_label.set_size_request(16, -1)
      number_label.override_color(:normal, Gdk::RGBA::new(0.5, 0.5, 0.5, 1.0))
      number_label.override_font(Pango::FontDescription.new('Sans 7'))
      
      # Имя файла
      file_name = File.basename(file_path)
      name_label = Gtk::Label.new(file_name)
      name_label.set_xalign(0.0)
      name_label.override_font(Pango::FontDescription.new('Sans 7'))
      name_label.override_color(:normal, Gdk::RGBA::new(0.9, 0.9, 0.9, 1.0))
      name_label.set_ellipsize(:middle)
      
      # Путь
      dir_path = File.dirname(file_path)
      if dir_path != "." && dir_path != "/"
        short_path = truncate_path(dir_path, 15)
        path_label = Gtk::Label.new(" (#{short_path})")
        path_label.override_font(Pango::FontDescription.new('Sans 6'))
        path_label.override_color(:normal, Gdk::RGBA::new(0.6, 0.6, 0.6, 1.0))
        path_label.set_ellipsize(:middle)
      else
        path_label = nil
      end
      
      # Упаковываем элементы
      row.pack_start(number_label, expand: false, fill: false, padding: 2)
      row.pack_start(name_label, expand: true, fill: true, padding: 2)
      row.pack_start(path_label, expand: false, fill: false, padding: 2) if path_label
      
      # EventBox для кликабельности
      event_box = Gtk::EventBox.new
      event_box.add(row)
      
      # Только один обработчик клика
      event_box.signal_connect('button-press-event') do |widget, event|
        if event.button == 1 && !popup_destroyed
          pane.load_file(file_path)
          safe_destroy.call
        end
        true
      end
      
      # Hover эффект
      event_box.signal_connect('enter-notify-event') do
        row.override_background_color(:normal, Gdk::RGBA::new(0.2, 0.4, 0.8, 1.0))
        false
      end
      
      event_box.signal_connect('leave-notify-event') do
        row.override_background_color(:normal, Gdk::RGBA::new(0.15, 0.15, 0.15, 1.0))
        false
      end
      
      list_container.pack_start(event_box, expand: false, fill: false, padding: 0)
    end
    
    # Размер окна
    popup_height = [history.length * 18, 200].min
    popup.set_size_request(300, popup_height)
    popup.add(list_container)
    
    # Простое позиционирование
    position_popup_simple(popup, pane)
    
    # Только один обработчик для закрытия по Escape
    popup.signal_connect('key-press-event') do |widget, event|
      if event.keyval == Gdk::Keyval::KEY_Escape
        safe_destroy.call
        true
      else
        false
      end
    end
    
    popup
  end

  def position_popup_simple(popup, pane)
    # Получаем позицию кнопки истории
    buttons_box = pane.instance_variable_get(:@buttons_box)
    history_button = buttons_box.children.find { |child| 
      child.instance_variable_get(:@action) == :history rescue false
    }
    
    if history_button
      # Безопасное получение координат
      begin
        if history_button.window
          button_x, button_y = history_button.window.get_root_coords(0, 0)
          button_width = history_button.allocation.width
          button_height = history_button.allocation.height
          
          # Позиционируем под кнопкой справа
          popup_x = button_x + button_width - 300  # Выравниваем по правому краю
          popup_y = button_y + button_height
          
          # Простая проверка границ
          if popup_x < 0
            popup_x = 0
          end
          if popup_y < 0
            popup_y = 0
          end
          
          popup.move(popup_x, popup_y)
        else
          # Fallback если нет window
          popup.move(200, 200)
        end
      rescue => e
        puts "Error positioning popup: #{e.message}"
        popup.move(200, 200)
      end
    else
      # Fallback если кнопка не найдена
      popup.move(200, 200)
    end
  end

  def swap_with_active(clicked_pane)
    puts "=== SWAP DEBUG ==="
    puts "Active pane: #{@active_pane.pane_id}"
    puts "Clicked pane: #{clicked_pane.pane_id}"
    puts "Active has_file: #{@active_pane.has_file?}"
    puts "Clicked has_file: #{clicked_pane.has_file?}"
    puts "Active is_new: #{@active_pane.is_new_file?}"
    puts "Clicked is_new: #{clicked_pane.is_new_file?}"
    puts "Active content length: #{@active_pane.get_current_editor.get_content.strip.length}"
    puts "Clicked content length: #{clicked_pane.get_current_editor.get_content.strip.length}"
    
    return unless @active_pane
    return if @active_pane == clicked_pane
    return unless @active_pane.has_file? && clicked_pane.has_file?
    
    puts "Starting swap..."
    
    # Обмениваем редакторы между панелями
    @active_pane.swap_editors_with(clicked_pane)
    
    # Устанавливаем фокус на панель куда кликнули
    @active_pane = clicked_pane
    clicked_pane.set_focus
    
    puts "Swap completed!"
    puts "=================="
    
    emit_modified
  end

  def close_pane(pane)
    # Не закрываем последнюю панель только если она единственная
    return if @panes.length <= 1
    
    @panes.delete(pane)
    @container.remove_pane(pane)
    @active_pane = @panes.first if @active_pane == pane
  end

  def emit_modified
    @on_modified_callbacks.each(&:call)
  end

  def create_grid_from_files(file_paths)
    return if file_paths.empty?
    
    # Вычисляем размеры grid
    total_files = file_paths.length
    cols = Math.sqrt(total_files).ceil
    rows = (total_files.to_f / cols).ceil
    
    puts "Creating grid: #{rows}x#{cols} for #{total_files} files"
    
    # Создаем панели для каждого файла
    file_paths.each_with_index do |file_path, index|
      pane = create_pane
      pane.load_file(file_path)
    end
    
    # Создаем grid-сетку
    create_grid_layout(rows, cols)
  end

  def create_grid_layout(rows, cols)
    return if @panes.empty?
    
    # Создаем строки
    row_containers = []
    rows.times do |row|
      row_start = row * cols
      row_panes = @panes[row_start, cols] || []
      next if row_panes.empty?
      
      if row_panes.size == 1
        # Одна панель в строке
        row_containers << row_panes.first.widget
      else
        # Создаем горизонтальную цепочку Paned для строки
        row_widget = create_horizontal_chain(row_panes)
        row_containers << row_widget
      end
    end
    
    # Создаем вертикальную цепочку для строк
    main_widget = if row_containers.size == 1
      row_containers.first
    else
      create_vertical_chain(row_containers)
    end
    
    # Удаляем виджеты из текущих родителей
    @panes.each do |pane|
      if pane.widget.parent
        pane.widget.parent.remove(pane.widget)
      end
    end
    
    # Создаем контейнер
    main_container = Gtk::Box.new(:vertical, 0)
    main_container.pack_start(main_widget, expand: true, fill: true, padding: 0)
    
    # Устанавливаем новый контейнер как корневой
    @container.set_root_container(main_container)
    
    # Помечаем что мы в grid режиме
    @grid_mode = true
  end
  
  def create_horizontal_chain(panes)
    return panes.first.widget if panes.size == 1
    
    # Создаем цепочку горизонтальных Paned
    root_paned = Gtk::Paned.new(:horizontal)
    root_paned.pack1(panes.first.widget, expand: true, shrink: false)
    
    current_paned = root_paned
    panes[1..-1].each_with_index do |pane, index|
      if index == panes.size - 2
        # Последняя панель
        current_paned.pack2(pane.widget, expand: true, shrink: false)
      else
        # Промежуточная панель
        new_paned = Gtk::Paned.new(:horizontal)
        new_paned.pack1(pane.widget, expand: true, shrink: false)
        current_paned.pack2(new_paned, expand: true, shrink: false)
        current_paned = new_paned
      end
    end
    
    # Устанавливаем равномерные позиции
    set_equal_positions(root_paned, panes.size)
    
    root_paned
  end
  
  def create_vertical_chain(widgets)
    return widgets.first if widgets.size == 1
    
    # Создаем цепочку вертикальных Paned
    root_paned = Gtk::Paned.new(:vertical)
    root_paned.pack1(widgets.first, expand: true, shrink: false)
    
    current_paned = root_paned
    widgets[1..-1].each_with_index do |widget, index|
      if index == widgets.size - 2
        # Последний виджет
        current_paned.pack2(widget, expand: true, shrink: false)
      else
        # Промежуточный виджет
        new_paned = Gtk::Paned.new(:vertical)
        new_paned.pack1(widget, expand: true, shrink: false)
        current_paned.pack2(new_paned, expand: true, shrink: false)
        current_paned = new_paned
      end
    end
    
    # Устанавливаем равномерные позиции
    set_equal_positions(root_paned, widgets.size)
    
    root_paned
  end
  
  def set_equal_positions(paned, total_items)
    # Устанавливаем позицию после показа окна
    GLib::Timeout.add(50) do
      if paned.allocated_width > 0 && paned.allocated_height > 0
        if paned.orientation == :horizontal
          position = paned.allocated_width / total_items
        else
          position = paned.allocated_height / total_items
        end
        paned.position = position
      end
      false # не повторять
    end
  end
  
  def exit_grid_mode
    return unless @grid_mode
    
    # Возвращаемся к обычному режиму с одной активной панелью
    if @active_pane
      @container.set_root(@active_pane)
      @panes = [@active_pane]
    else
      # Создаем новую панель если нет активной
      setup_initial_pane
    end
    
    @grid_mode = false
  end

  def truncate_path(path, max_length = 25)
    return path if path.length <= max_length
    
    # Обрезаем посередине с многоточием
    left_part = path[0, (max_length - 3) / 2]
    right_part = path[-(max_length - 3 - left_part.length)..-1]
    
    "#{left_part}...#{right_part}"
  end
end 