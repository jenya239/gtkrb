require_relative '../src/file_tree_state'

class TreeController
  attr_reader :model, :state, :events
  
  def initialize(model, state, events)
    @model = model
    @state = state
    @events = events
  end
  
  def expand_item(item)
    return unless @model.can_expand?(item)
    @state.expand(item)
    @events.emit(:tree_changed, item)
  end
  
  def collapse_item(item)
    @state.collapse(item)
    @events.emit(:tree_changed, item)
  end
  
  def toggle_expand(item)
    if @state.expanded?(item)
      collapse_item(item)
    else
      expand_item(item)
    end
  end
  
  def select_item(item)
    @state.select_item(item)
    @events.emit(:item_selected, item)
  end
  
  def activate_item(item)
    @events.emit(:item_activated, item)
  end
  
  def scroll_to(offset)
    @state.scroll_offset = [offset, 0].max
    @events.emit(:view_changed)
  end
  
  def scroll_by(delta)
    new_offset = @state.scroll_offset + delta
    scroll_to(new_offset)
  end
  
  def select_next
    items = get_flat_items
    return if items.empty?
    
    current_idx = items.index(@state.selected_item) || -1
    new_idx = [current_idx + 1, items.size - 1].min
    select_item(items[new_idx])
  end
  
  def select_previous
    items = get_flat_items
    return if items.empty?
    
    current_idx = items.index(@state.selected_item) || -1
    new_idx = [current_idx - 1, 0].max
    select_item(items[new_idx])
  end
  
  def handle_key(key)
    case key
    when :up then select_previous
    when :down then select_next
    when :enter, :return then activate_item(@state.selected_item) if @state.selected_item
    when :space then toggle_expand(@state.selected_item) if @state.selected_item
    end
  end
  
  def get_visible_items
    @model.get_flat_tree
  end
  
  def change_directory(path)
    @model.change_directory(path)
    @state.clear
    @events.emit(:directory_changed, path)
  end
  
  def refresh
    @events.emit(:refresh_requested)
  end
  
  private
  
  def get_flat_items
    get_visible_items.map(&:first)
  end
end 