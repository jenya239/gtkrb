require_relative '../../../components/tree_view/platform/gtk3/gtk3_tree_widget'

class FileTreePanel
  attr_reader :widget
  
  def initialize(path = Dir.pwd)
    @tree_widget = GTK3TreeWidget.new(path)
    @scrolled = Gtk::ScrolledWindow.new
    @scrolled.set_policy(:automatic, :automatic)
    @scrolled.set_hexpand(true)
    @scrolled.set_vexpand(true)
    
    @scrolled.add(@tree_widget)
    
    # Используем только скроллированное дерево без label
    @widget = @scrolled
    
    @file_selected_callback = nil
    setup_signals
  end
  
  def on_file_selected(&block)
    @file_selected_callback = block
  end
  
  def refresh
    @tree_widget.refresh
  end
  
  def current_path
    @tree_widget.current_path
  end
  
  def change_directory(path)
    @tree_widget.change_directory(path)
  end
  
  def on_directory_changed(&block)
    @directory_changed_callback = block
  end
  
  private
  
  def setup_signals
    @tree_widget.on_item_selected do |item|
      if item.type == :file
        @file_selected_callback&.call(item.path)
      end
    end
    
    @tree_widget.on_item_activated do |item|
      case item.type
      when :file
        @file_selected_callback&.call(item.path)
      when :directory, :parent
        # Для директорий переходим в них
        change_directory(item.path)
      end
    end
    
    @tree_widget.on_directory_changed do |path|
      # Обновляем заголовок панели через callback если он есть
      @directory_changed_callback&.call(path) if @directory_changed_callback
    end
  end
end 