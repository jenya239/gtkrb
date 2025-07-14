require 'gtk3'
require_relative '../../core/tree_controller'
require_relative '../../core/tree_events'
require_relative '../../core/file_tree_model'
require_relative '../../presentation/tree_theme'
require_relative '../../input/input_controller'
require_relative 'gtk3_cairo_renderer'
require_relative 'gtk3_event_adapter'

class GTK3TreeWidget < Gtk::DrawingArea
  attr_reader :tree_controller, :renderer, :input_controller
  
  def initialize(root_path = Dir.pwd)
    super()
    
    # Создаем все слои
    @model = FileTreeModel.new(root_path)
    @events = TreeEvents.new
    @tree_controller = TreeController.new(@model, @model.state, @events)
    
    @theme = TreeTheme.new
    @renderer = GTK3CairoRenderer.new(@theme)
    @input_controller = InputController.new(@tree_controller, @renderer)
    
    # Настраиваем виджет
    setup_widget
    
    # Подключаем события
    @event_adapter = GTK3EventAdapter.new(self, @input_controller)
    
    # Подключаем коллбеки
    setup_callbacks
  end
  
  def on_item_selected(&block)
    @events.on(:item_selected, &block)
  end
  
  def on_item_activated(&block)
    @events.on(:item_activated, &block)
  end
  
  def on_directory_changed(&block)
    @events.on(:directory_changed, &block)
  end
  
  def refresh
    @tree_controller.refresh
    invalidate_layout
    queue_draw
  end
  
  def change_directory(path)
    @tree_controller.change_directory(path)
    invalidate_layout
    queue_draw
  end
  
  def current_path
    @model.current_path
  end
  
  private
  
  def setup_widget
    set_hexpand(true)
    set_vexpand(true)
    set_size_request(-1, 200)
    
    # Подключаем обработчик отрисовки
    signal_connect("draw") { |_, cr| draw(cr) }
  end
  
  def setup_callbacks
    # Обновляем виджет при изменениях
    @events.on(:tree_changed) { invalidate_and_redraw }
    @events.on(:item_selected) { queue_draw }
    @events.on(:view_changed) { queue_draw }
    @events.on(:directory_changed) { invalidate_and_redraw }
    @events.on(:refresh_requested) { invalidate_and_redraw }
    @events.on(:hover_changed) { queue_draw }
  end
  
  def draw(cr)
    allocation = self.allocation
    width = allocation.width
    height = allocation.height
    
    # Получаем видимые элементы
    items = @tree_controller.get_visible_items
    
    # Ограничиваем скролл offset
    max_scroll = [(@renderer.get_total_height - height).to_i, 0].max
    if @model.state.scroll_offset > max_scroll
      @model.state.scroll_offset = max_scroll
    end
    
    # Рендерим через GTK3CairoRenderer
    @renderer.render_tree_gtk3(cr, width, height, items, @model.state)
    
    false
  end
  
  def invalidate_layout
    @renderer.invalidate_layout
  end
  
  def invalidate_and_redraw
    invalidate_layout
    queue_draw
  end
end 