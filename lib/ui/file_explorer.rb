require_relative '../../components/tree_view/src/tree_view'
require_relative '../../components/tree_view/src/file_tree_adapter'

class FileExplorer
  def initialize
    @data_source = FileTreeAdapter.new(Dir.pwd)
    @tree = TreeView.new(@data_source)
    @tree.set_hexpand(true)
    @tree.set_vexpand(true)
    @scrolled = Gtk::ScrolledWindow.new
    @scrolled.set_policy(:automatic, :automatic)
    @scrolled.set_hexpand(true)
    @scrolled.set_vexpand(true)
    @scrolled.add(@tree)
    @label = Gtk::Label.new(@data_source.current_path)
    @label.set_xalign(0)
    @label.set_hexpand(true)
    @label.set_vexpand(false)
    @label.override_font(Pango::FontDescription.new('Sans 8'))
    @box = Gtk::Box.new(:vertical, 0)
    @box.set_hexpand(true)
    @box.set_vexpand(true)
    @box.override_background_color(:normal, Gdk::RGBA::new(1,1,1,1))
    @scrolled.override_background_color(:normal, Gdk::RGBA::new(1,1,1,1))
    @tree.override_background_color(:normal, Gdk::RGBA::new(1,1,1,1))
    @box.pack_start(@label, expand: false, fill: true, padding: 2)
    @box.pack_start(@scrolled, expand: true, fill: true, padding: 0)
    @box.set_size_request(-1, 300)
    setup_signals
  end

  def widget
    @box
  end

  def on_file_selected(&block)
    @file_selected_callback = block
  end
  
  def refresh
    @tree.refresh
    @label.text = @data_source.current_path
  end
  
  def load_directory(path)
    @data_source.change_directory(path)
    refresh
  end
  
  private
  
  def setup_signals
    @tree.on_item_selected do |item|
      handle_item_single_click(item)
    end
    @tree.on_item_activated do |item|
      handle_item_double_click(item)
    end
  end

  def handle_item_single_click(item)
    case item.type
    when :file
      @file_selected_callback&.call(item.path)
    when :directory
      # Для директорий просто раскрываем/сворачиваем
      @tree.toggle_expand(item) if @data_source.can_expand?(item)
    when :parent
      # Для родительской директории (..) ничего не делаем при одиночном клике
    end
  end

  def handle_item_double_click(item)
    case item.type
    when :directory, :parent
      # При двойном клике переходим в директорию
      @data_source.change_directory(item.path)
      refresh
    when :file
      # При двойном клике на файл также вызываем callback
      @file_selected_callback&.call(item.path)
    end
  end
end