require 'gtk4'
require 'gtksourceview5'
require_relative '../core/language_manager'

class CodeEditor
  def initialize
    @view = GtkSource::View.new
    @buffer = @view.buffer
    @language_manager = LanguageManager.new
    setup_editor
  end

  def widget
    scrolled = Gtk::ScrolledWindow.new
    scrolled.set_child(@view)
    scrolled
  end

  def load_file(file_path)
    content = File.read(file_path)
    @buffer.text = content
    
    lang = @language_manager.get_language(file_path)
    @buffer.language = lang if lang
  rescue => e
    @buffer.text = "# Error reading file: #{e.message}"
  end

  private

  def setup_editor
    @view.set_show_line_numbers(true)
    @view.set_highlight_current_line(true)
  end
end 