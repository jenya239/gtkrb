require 'gtk3'
require_relative 'file_explorer'
require_relative 'code_editor'

class MainWindow
  def initialize(application)
    @win = Gtk::Window.new
    @file_explorer = FileExplorer.new
    @code_editor = CodeEditor.new
    setup_window
    setup_layout
    connect_signals
    @code_editor.on_modified { update_title }
  end

  def present
    @win.show_all
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
    paned.pack2(@code_editor.widget, resize: true, shrink: true)
    paned.set_position(200)
    @win.add(paned)
  end

  def connect_signals
    @file_explorer.on_file_selected do |file_path|
      @code_editor.load_file(file_path)
      update_title
    end
  end

  def update_title
    path = @code_editor.file_path
    mark = @code_editor.modified? ? "*" : ""
    if path
      @win.set_title("Editor#{mark} - #{path}")
    else
      @win.set_title("Editor")
    end
  end
end 