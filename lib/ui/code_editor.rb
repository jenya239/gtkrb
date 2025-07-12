require 'gtk4'
require 'gtksourceview5'
require_relative '../core/language_manager'
require_relative 'widgets/minimap'

class CodeEditor
  def initialize
    @view = GtkSource::View.new
    @buffer = @view.buffer
    @language_manager = LanguageManager.new
    @file_path = nil
    @modified = false
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
    @file_path = file_path
    content = File.read(file_path)
    @buffer.text = content
    lang = @language_manager.get_language(file_path)
    @buffer.language = lang if lang
    @modified = false
    emit_modified
  rescue => e
    @buffer.text = "# Error reading file: #{e.message}"
    @modified = false
    emit_modified
  end

  def save_file
    return unless @file_path
    File.write(@file_path, @buffer.text)
    @modified = false
    emit_modified
  end

  def modified?
    @modified
  end

  def file_path
    @file_path
  end

  def on_modified(&block)
    @on_modified = block
  end

  private

  def setup_editor
    @view.set_show_line_numbers(true)
    @view.set_highlight_current_line(true)
    css_provider = Gtk::CssProvider.new
    css_provider.load_from_data("textview { font-family: 'Fira Mono', monospace; font-size: 10px; }")
    @view.style_context.add_provider(css_provider, 600)
    @view.set_wrap_mode(:word_char)
    @view.set_auto_indent(true)
    @view.set_tab_width(2)
    @view.set_indent_width(2)
    @view.set_insert_spaces_instead_of_tabs(true)
    @buffer.signal_connect("changed") do
      unless @modified
        @modified = true
        emit_modified
      end
    end
    # Ctrl+S
    key = Gtk::EventControllerKey.new
    key.signal_connect("key-pressed") do |_, keyval, _, state|
      if keyval == Gdk::Keyval::KEY_s && (state & Gdk::ModifierType::CONTROL_MASK) != 0
        save_file
        true
      else
        false
      end
    end
    @view.add_controller(key)
  end

  def emit_modified
    @on_modified.call if @on_modified
  end
end 