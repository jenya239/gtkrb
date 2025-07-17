require 'gtk3'
require_relative 'file_explorer'
require_relative 'editor_manager'
require_relative 'split_container'

class MainWindow
  def initialize(application = nil)
    @win = Gtk::Window.new
    @file_explorer = FileExplorer.new
    @split_container = SplitContainer.new
    @editor_manager = EditorManager.new(@split_container, @file_explorer)
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

  def setup_window
    @win.set_title("Editor")
    @win.set_default_size(1200, 700)
    @win.signal_connect("destroy") { Gtk.main_quit }
  end

  def setup_layout
    paned = Gtk::Paned.new(:horizontal)
    paned.pack1(@file_explorer.widget, resize: false, shrink: true)
    paned.pack2(@split_container.widget, resize: true, shrink: true)
    paned.set_position(300)
    @win.add(paned)
  end

  def connect_signals
    @file_explorer.on_file_selected do |file_path|
      @editor_manager.load_file(file_path)
      update_title
    end
    
    # Обновляем панель файлов при сохранении
    @editor_manager.on_file_saved do |file_path|
      @file_explorer.refresh
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
    
    # Ctrl+W - закрыть панель
    if event.state.control_mask? && event.keyval == Gdk::Keyval::KEY_w
      @editor_manager.close_active_pane
      return true
    end
    
    false
  end
end 