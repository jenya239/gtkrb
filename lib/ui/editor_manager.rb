require 'gtk3'
require_relative 'editor_pane'
require_relative 'split_container'

class EditorManager
  def initialize
    @panes = []
    @active_pane = nil
    @container = SplitContainer.new
    @on_modified_callbacks = []
    setup_initial_pane
  end

  def widget
    @container.widget
  end

  def load_file(file_path)
    # Открываем файл в активном редакторе
    if @active_pane
      @active_pane.load_file(file_path)
    else
      create_pane.load_file(file_path)
    end
  end

  def split_horizontal
    new_pane = create_pane
    @container.split_horizontal(@active_pane, new_pane)
    @active_pane = new_pane
  end

  def split_vertical
    new_pane = create_pane
    @container.split_vertical(@active_pane, new_pane)
    @active_pane = new_pane
  end

  def close_active_pane
    close_pane(@active_pane) if @active_pane
  end

  def on_modified(&block)
    @on_modified_callbacks << block
  end

  def get_active_pane
    @active_pane
  end

  def get_all_panes
    @panes.dup
  end

  def get_active_file
    @active_pane ? @active_pane.get_current_file : nil
  end

  private

  def setup_initial_pane
    @active_pane = create_pane
    @container.set_root(@active_pane)
  end

  def create_pane
    pane = EditorPane.new
    @panes << pane
    
    pane.on_focus { |p| @active_pane = p }
    pane.on_modified { emit_modified }
    pane.on_button { |clicked_pane| swap_with_active(clicked_pane) }
    
    pane
  end

  def swap_with_active(clicked_pane)
    return unless @active_pane
    return if @active_pane == clicked_pane
    return unless @active_pane.has_file? && clicked_pane.has_file?
    
    # Меняем файлы местами
    active_file = @active_pane.get_current_file
    clicked_file = clicked_pane.get_current_file
    
    @active_pane.load_file(clicked_file)
    clicked_pane.load_file(active_file)
    
    emit_modified
  end

  def close_pane(pane)
    # Не закрываем последнюю панель только если она единственная
    return if @panes.length <= 1
    
    @panes.delete(pane)
    @container.remove_pane(pane)
    @active_pane = @panes.first if @active_pane == pane
  end

  def emit_modified
    @on_modified_callbacks.each(&:call)
  end
end 