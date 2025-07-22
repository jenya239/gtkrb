require 'gtk3'
require_relative 'widgets/file_tree_panel'
require_relative 'managers/editor_manager'
require_relative 'containers/split_container'

class MainWindow
  def initialize(application = nil)
    @win = Gtk::Window.new
    @file_tree_panel = create_file_tree_panel
    @split_container = SplitContainer.new
    @editor_manager = EditorManager.new(@split_container)
    setup_window
    setup_layout
    connect_signals
    @editor_manager.on_modified { update_title }
  end

  def present
    @win.show_all
  end

  def editor_manager
    @editor_manager
  end

  def show_all
    @win.show_all
  end

  def signal_connect(signal, &block)
    @win.signal_connect(signal, &block)
  end

  private

  def create_file_tree_panel
    # Создаем панель файлов с Matrix стилизацией
    panel = FileTreePanel.new(Dir.pwd)
    
    # Создаем контейнер с кнопками переключения
    container = Gtk::Box.new(:vertical, 0)
    
    # Создаем заголовок с кнопками
    header = Gtk::Box.new(:horizontal, 0)
    header.set_hexpand(true)
    
    # Путь
    path_label = Gtk::Label.new(truncate_path(Dir.pwd))
    path_label.set_xalign(0)
    path_label.set_hexpand(true)
    path_label.override_font(Pango::FontDescription.new('Monospace Bold 8'))
    path_label.override_color(:normal, Gdk::RGBA::new(0.0, 1.0, 0.2, 0.9))
    
    # Кнопки переключения типов
    buttons_box = Gtk::Box.new(:horizontal, 0)
    
    # Кнопка файлового дерева (активная)
    tree_button = create_type_button("📁", true)
    
    # Кнопка редактора  
    editor_button = create_type_button("📝", false)
    editor_button.signal_connect('button-press-event') do |widget, event|
      convert_left_panel_to_editor
      true
    end
    
    # Кнопка терминала
    terminal_button = create_type_button("⚑", false)
    terminal_button.signal_connect('button-press-event') do |widget, event|
      convert_left_panel_to_terminal
      true
    end
    
    buttons_box.pack_start(tree_button, false, false, 0)
    buttons_box.pack_start(editor_button, false, false, 0)
    buttons_box.pack_start(terminal_button, false, false, 0)
    
    header.pack_start(path_label, true, true, 5)
    header.pack_end(buttons_box, false, false, 2)
    
    # Обновляем путь при изменении директории
    panel.on_directory_changed do |new_path|
      path_label.text = truncate_path(new_path)
    end
    
    container.pack_start(header, false, false, 3)
    container.pack_start(panel.widget, true, true, 0)
    
    # Стилизация
    container.override_background_color(:normal, Gdk::RGBA::new(0.05, 0.05, 0.05, 1.0))
    container.set_size_request(-1, 300)
    
    # Возвращаем объект с методами panel
    wrapper = Object.new
    wrapper.define_singleton_method(:widget) { container }
    wrapper.define_singleton_method(:on_file_selected) { |&block| panel.on_file_selected(&block) }
    wrapper.define_singleton_method(:refresh) { panel.refresh }
    
    wrapper
  end
  
  def create_type_button(text, active)
    button = Gtk::EventBox.new
    label = Gtk::Label.new(text)
    label.set_size_request(14, 14)
    label.override_font(Pango::FontDescription.new('Monospace Bold 8'))
    
    if active
      label.override_color(:normal, Gdk::RGBA::new(0.0, 1.0, 0.2, 1.0))
    else
      label.override_color(:normal, Gdk::RGBA::new(0.5, 0.5, 0.5, 1.0))
    end
    
    button.add(label)
    button.set_size_request(14, 14)
    button
  end
  
  def convert_left_panel_to_editor
    # Создаем новую панель редактора
    @editor_manager.create_pane
  end
  
  def convert_left_panel_to_terminal
    # Создаем новую панель терминала
    @editor_manager.convert_pane_to_terminal
  end
  
  def truncate_path(path, max_length = 30)
    return path if path.length <= max_length
    
    # Сокращаем посередине с многоточием
    left_part = path[0, (max_length - 3) / 2]
    right_part = path[-(max_length - 3 - left_part.length)..-1]
    
    "#{left_part}...#{right_part}"
  end

  def setup_window
    @win.set_title("Editor")
    @win.set_default_size(1200, 700)
    @win.signal_connect("destroy") { Gtk.main_quit }
  end

  def setup_layout
    paned = Gtk::Paned.new(:horizontal)
    paned.pack1(@file_tree_panel.widget, resize: false, shrink: true)
    paned.pack2(@split_container.widget, resize: true, shrink: true)
    paned.set_position(300)
    @win.add(paned)
  end

  def connect_signals
    @file_tree_panel.on_file_selected do |file_path|
      @editor_manager.load_file(file_path)
      update_title
    end
    
    # Обновляем панель файлов при сохранении
    @editor_manager.on_file_saved do |file_path|
      @file_tree_panel.refresh
      update_title
    end
    
    # Горячие клавиши
    @win.signal_connect('key-press-event') do |widget, event|
      handle_key_press(event)
    end
  end

  def update_title
    active_pane = @editor_manager.get_active_pane
    if active_pane && active_pane.get_current_editor
      editor = active_pane.get_current_editor
      path = editor.file_path
      mark = editor.modified? ? "*" : ""
      if path
        @win.set_title("Editor#{mark} - #{File.basename(path)}")
      else
        @win.set_title("Editor")
      end
    else
      @win.set_title("Editor")
    end
  end

  def handle_key_press(event)
    # Ctrl+Shift+E - горизонтальное разделение
    if event.state.control_mask? && event.state.shift_mask? && event.keyval == Gdk::Keyval::KEY_E
      @editor_manager.split_horizontal
      return true
    end
    
    # Ctrl+Shift+O - вертикальное разделение
    if event.state.control_mask? && event.state.shift_mask? && event.keyval == Gdk::Keyval::KEY_O
      @editor_manager.split_vertical
      return true
    end
    
    # Ctrl+Shift+F - превратить панель в файловое дерево
    if event.state.control_mask? && event.state.shift_mask? && event.keyval == Gdk::Keyval::KEY_F
      @editor_manager.convert_pane_to_file_tree
      return true
    end
    
    # Ctrl+Shift+R - превратить панель в редактор
    if event.state.control_mask? && event.state.shift_mask? && event.keyval == Gdk::Keyval::KEY_R
      @editor_manager.convert_pane_to_editor
      return true
    end
    
    # Ctrl+W - закрыть панель
    if event.state.control_mask? && event.keyval == Gdk::Keyval::KEY_w
      @editor_manager.close_active_pane
      return true
    end
    
    false
  end
end 