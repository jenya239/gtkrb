require 'gtk4'
require_relative 'file_explorer'
require_relative 'code_editor'

class MainWindow
  def initialize(application)
    @win = Gtk::ApplicationWindow.new(application)
    @file_explorer = FileExplorer.new
    @code_editor = CodeEditor.new
    setup_window
    setup_layout
    connect_signals
    @code_editor.on_modified { update_title }
  end

  def present
    @win.present
  end

  private

  def setup_window
    @win.set_title("Editor")
    @win.set_default_size(1200, 700)
  end

  def setup_layout
    paned = Gtk::Paned.new(:horizontal)
    paned.set_start_child(@file_explorer.widget)
    paned.set_end_child(@code_editor.widget)
    paned.set_position(200)
    @win.set_child(paned)
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