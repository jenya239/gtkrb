require_relative '../../components/tree_view/platform/gtk3/gtk3_tree_widget'

class FileExplorer
  def initialize
    @tree_widget = GTK3TreeWidget.new(Dir.pwd)
    @scrolled = Gtk::ScrolledWindow.new
    @scrolled.set_policy(:automatic, :automatic)
    @scrolled.set_hexpand(true)
    @scrolled.set_vexpand(true)
    
    # Стилизация скроллбара
    setup_scrollbar_style
    
    @scrolled.add(@tree_widget)
    
    # Стиль path label в solarized lite
    @label = Gtk::Label.new(truncate_path(@tree_widget.current_path))
    @label.set_xalign(0)
    @label.set_hexpand(true)
    @label.set_vexpand(false)
    @label.override_font(Pango::FontDescription.new('Sans 8'))
    @label.override_color(:normal, Gdk::RGBA::new(0.345, 0.431, 0.459, 1.0))  # Solarized base01
    
    @box = Gtk::Box.new(:vertical, 0)
    @box.set_hexpand(true)
    @box.set_vexpand(true)
    @box.override_background_color(:normal, Gdk::RGBA::new(0.992, 0.965, 0.890, 1.0))  # Solarized base3
    @scrolled.override_background_color(:normal, Gdk::RGBA::new(0.992, 0.965, 0.890, 1.0))
    @tree_widget.override_background_color(:normal, Gdk::RGBA::new(0.992, 0.965, 0.890, 1.0))
    
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
    @tree_widget.refresh
    @label.text = truncate_path(@tree_widget.current_path)
  end
  
  def load_directory(path)
    @tree_widget.change_directory(path)
    @label.text = truncate_path(@tree_widget.current_path)
  end
  
  private
  
  def setup_signals
    @tree_widget.on_item_selected do |item|
      handle_item_single_click(item)
    end
    @tree_widget.on_item_activated do |item|
      handle_item_double_click(item)
    end
    @tree_widget.on_directory_changed do |path|
      @label.text = truncate_path(path)
    end
  end

  def handle_item_single_click(item)
    case item.type
    when :file
      @file_selected_callback&.call(item.path)
    when :directory
      # Для директорий просто раскрываем/сворачиваем
      # Это уже обрабатывается в GTK3TreeWidget
    when :parent
      # Для родительской директории (..) ничего не делаем при одиночном клике
    end
  end

  def handle_item_double_click(item)
    case item.type
    when :directory, :parent
      # При двойном клике переходим в директорию
      load_directory(item.path)
    when :file
      # При двойном клике на файл также вызываем callback
      @file_selected_callback&.call(item.path)
    end
  end

  def truncate_path(path, max_length = 30)
    return path if path.length <= max_length
    
    # Показываем начало и конец пути
    if path.length > max_length
      start_length = (max_length - 3) / 2
      end_length = max_length - 3 - start_length
      "#{path[0, start_length]}...#{path[-end_length, end_length]}"
    else
      path
    end
  end
  
  def setup_scrollbar_style
    # Создаем CSS провайдер для стилизации скроллбара
    css_provider = Gtk::CssProvider.new
    css_provider.load_from_data(<<~CSS)
      scrolledwindow {
        background: transparent;
      }
      
      scrollbar {
        background: transparent;
        border: none;
        border-radius: 0;
      }
      
      scrollbar slider {
        background: rgba(88, 110, 117, 0.3);
        border: none;
        border-radius: 4px;
        min-width: 6px;
        min-height: 6px;
        margin: 1px;
      }
      
      scrollbar:hover slider {
        background: rgba(88, 110, 117, 0.6);
        min-width: 8px;
      }
      
      scrollbar trough {
        background: transparent;
        border: none;
      }
      
      scrollbar button {
        opacity: 0;
        min-width: 0;
        min-height: 0;
      }
    CSS
    
    # Применяем стиль к скролл окну
    context = @scrolled.style_context
    context.add_provider(css_provider, Gtk::StyleProvider::PRIORITY_USER)
  end
end