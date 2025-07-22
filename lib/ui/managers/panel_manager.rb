require_relative 'panel_factory'
require_relative 'split_container'

class PanelManager
  def initialize(container)
    @container = container
    @panels = []
    @active_panel = nil
    @grid_mode = false
    @on_modified_callbacks = []
    @on_file_saved_callback = nil
    @current_popup = nil
    
    setup_initial_panel
  end

  def widget
    @container.widget
  end

  def load_file(file_path)
    if @active_panel&.panel_type == :editor
      @active_panel.load_file(file_path)
    else
      # Создаем новую панель редактора
      panel = PanelFactory.create_editor_with_file(file_path)
      replace_active_panel(panel)
    end
  end

  def create_editor_panel
    panel = PanelFactory.create_panel(:editor)
    replace_active_panel(panel)
  end

  def create_terminal_panel(working_dir = nil)
    working_dir ||= get_current_directory
    panel = PanelFactory.create_panel(:terminal, working_dir: working_dir)
    replace_active_panel(panel)
  end

  def create_file_manager_panel(root_dir = nil)
    root_dir ||= get_current_directory
    panel = PanelFactory.create_panel(:file_manager, root_dir: root_dir)
    replace_active_panel(panel)
  end

  def split_horizontal
    if @grid_mode
      exit_grid_mode
    end
    
    if @active_panel
      new_panel = PanelFactory.create_panel(:editor)
      setup_panel_callbacks(new_panel)
      @container.split_horizontal(@active_panel, new_panel)
      @active_panel = new_panel
      @active_panel.focus
    end
  end

  def split_vertical
    if @grid_mode
      exit_grid_mode
    end
    
    if @active_panel
      new_panel = PanelFactory.create_panel(:editor)
      setup_panel_callbacks(new_panel)
      @container.split_vertical(@active_panel, new_panel)
      @active_panel = new_panel
      @active_panel.focus
    end
  end

  def close_panel(panel)
    return unless panel.can_close?
    
    @panels.delete(panel)
    
    if @panels.empty?
      setup_initial_panel
    else
      @container.remove_panel(panel)
      @active_panel = @panels.first
      @active_panel.set_active_style
    end
  end

  def on_modified(&block)
    @on_modified_callbacks << block
  end

  def on_file_saved(&block)
    @on_file_saved_callback = block
  end

  def enter_grid_mode
    return if @grid_mode
    
    # Создаем grid из всех панелей
    @container.set_grid_layout(@panels)
    @grid_mode = true
  end

  def exit_grid_mode
    return unless @grid_mode
    
    # Возвращаемся к обычному режиму с одной активной панелью
    if @active_panel
      @container.set_root(@active_panel)
      @panels = [@active_panel]
    else
      setup_initial_panel
    end
    
    @grid_mode = false
  end

  def grid_mode?
    @grid_mode
  end

  private

  def setup_initial_panel
    @active_panel = create_panel(:editor)
    @container.set_root(@active_panel)
    @grid_mode = false
  end

  def create_panel(type, options = {})
    panel = PanelFactory.create_panel(type, options)
    @panels << panel
    setup_panel_callbacks(panel)
    panel
  end

  def replace_active_panel(new_panel)
    old_panel = @active_panel
    @active_panel = new_panel
    @panels.delete(old_panel)
    @panels << new_panel
    
    setup_panel_callbacks(new_panel)
    @container.replace_panel(old_panel, new_panel)
    new_panel.set_active_style
    new_panel.focus
  end

  def setup_panel_callbacks(panel)
    panel.on_focus do |p|
      old_active = @active_panel
      @active_panel = p
      
      # Обновляем стили
      @panels.each { |panel| panel.set_inactive_style }
      p.set_active_style
    end
    
    panel.on_modified { emit_modified }
    panel.on_button { |clicked_panel| swap_with_active(clicked_panel) }
    panel.on_close { |p| close_panel(p) }
    panel.on_split_horizontal { |p| split_panel_horizontal(p) }
    panel.on_split_vertical { |p| split_panel_vertical(p) }
    panel.on_new_file { |p| create_new_file(p) }
    panel.on_save { |p| show_save_dialog(p) }
    panel.on_file_saved { |file_path| @on_file_saved_callback.call(file_path) if @on_file_saved_callback }
    panel.on_history { |p| show_file_history(p) }

    # Специфичные для типов панелей callbacks
    case panel.panel_type
    when :file_manager
      panel.on_file_selected { |file_path| load_file(file_path) }
    end
  end

  def split_panel_horizontal(panel)
    @active_panel = panel
    split_horizontal
  end

  def split_panel_vertical(panel)
    @active_panel = panel
    split_vertical
  end

  def create_new_file(panel)
    @active_panel = panel
    
    if panel.panel_type == :editor
      # Создаем новый файл в существующей панели редактора
      temp_file = "/tmp/untitled_#{Time.now.to_i}.txt"
      File.write(temp_file, "")
      panel.load_file(temp_file)
      panel.instance_variable_set(:@is_new_file, true)
      panel.instance_variable_set(:@original_temp_file, temp_file)
    else
      # Создаем новую панель редактора
      create_editor_panel
    end
  end

  def show_save_dialog(panel)
    return unless panel.panel_type == :editor
    
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
      current_content = panel.get_content
      
      begin
        File.write(filename, current_content)
        panel.mark_as_saved(filename)
        emit_modified
      rescue => e
        puts "Error saving file: #{e.message}"
      end
    end
    
    dialog.destroy
  end

  def show_file_history(panel)
    return unless panel.panel_type == :editor
    
    # Если попап уже открыт, закрываем его
    if @current_popup
      @current_popup.destroy
      @current_popup = nil
      return
    end
    
    history = panel.get_file_history
    return if history.empty?
    
    # Создаем компактный выпадающий список
    popup = create_compact_history_dropdown(panel, history)
    @current_popup = popup
    popup.show_all
  end

  def create_compact_history_dropdown(panel, history)
    # Создаем простое всплывающее окно
    popup = Gtk::Window.new(:popup)
    popup.set_type_hint(:dropdown_menu)
    popup.set_decorated(false)
    popup.set_resizable(false)
    popup.set_skip_taskbar_hint(true)
    popup.set_skip_pager_hint(true)
    
    # Контейнер для списка
    list_container = Gtk::Box.new(:vertical, 0)
    
    # Флаг для предотвращения двойного destroy
    popup_destroyed = false
    
    # Безопасная функция уничтожения
    safe_destroy = proc do
      unless popup_destroyed
        popup_destroyed = true
        @current_popup = nil
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
          panel.load_file(file_path)
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
    position_popup_simple(popup, panel)
    
    # Только один обработчик для закрытия по Escape
    popup.signal_connect('key-press-event') do |widget, event|
      if event.keyval == Gdk::Keyval::KEY_Escape
        safe_destroy.call
        true
      else
        false
      end
    end
    
    # Закрытие по потере фокуса
    popup.signal_connect('focus-out-event') do |widget, event|
      safe_destroy.call
      false
    end
    
    popup
  end

  def position_popup_simple(popup, panel)
    # Получаем позицию кнопки истории
    buttons_box = panel.instance_variable_get(:@buttons_box)
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
          popup_x = button_x + button_width - 300
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
          popup.move(200, 200)
        end
      rescue => e
        puts "Error positioning popup: #{e.message}"
        popup.move(200, 200)
      end
    else
      popup.move(200, 200)
    end
  end

  def swap_with_active(clicked_panel)
    # Логика для замены панелей
    puts "Swapping panels: #{@active_panel.panel_type} <-> #{clicked_panel.panel_type}"
    
    old_active = @active_panel
    @active_panel = clicked_panel
    
    # Обновляем стили
    @panels.each { |panel| panel.set_inactive_style }
    clicked_panel.set_active_style
    clicked_panel.focus
  end

  def get_current_directory
    if @active_panel
      case @active_panel.panel_type
      when :editor
        if @active_panel.has_file?
          File.dirname(@active_panel.instance_variable_get(:@current_file))
        else
          Dir.pwd
        end
      when :terminal
        @active_panel.get_working_dir
      when :file_manager
        @active_panel.get_current_dir
      else
        Dir.pwd
      end
    else
      Dir.pwd
    end
  end

  def emit_modified
    @on_modified_callbacks.each { |callback| callback.call }
  end

  def truncate_path(path, max_length = 25)
    return path if path.length <= max_length
    
    # Обрезаем посередине с многоточием
    left_part = path[0, (max_length - 3) / 2]
    right_part = path[-(max_length - 3 - left_part.length)..-1]
    
    "#{left_part}...#{right_part}"
  end
end 