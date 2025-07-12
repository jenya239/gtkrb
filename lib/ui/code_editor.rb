require 'gtk4'
require 'gtksourceview5'
require_relative '../core/language_manager'
require_relative 'widgets/minimap'

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
    scrolled.set_hexpand(true)
    scrolled.set_vexpand(true)
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
    
    # Моноширинный шрифт через CSS
    css_provider = Gtk::CssProvider.new
    css_provider.load_from_data("textview { font-family: 'Fira Mono', monospace; font-size: 10px; }")
    @view.style_context.add_provider(css_provider, 600)
    
    # Настройки редактора
    @view.set_wrap_mode(:word_char)
    @view.set_auto_indent(true)
    @view.set_tab_width(2)
    @view.set_indent_width(2)
    @view.set_insert_spaces_instead_of_tabs(true)
  end
end 