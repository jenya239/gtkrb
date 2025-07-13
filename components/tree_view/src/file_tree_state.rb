require 'set'

class FileTreeState
  attr_reader :expanded_items, :selected_item, :current_directory
  
  def initialize(current_directory = Dir.pwd)
    @expanded_items = Set.new
    @selected_item = nil
    @current_directory = current_directory
  end
  
  def expanded?(item)
    @expanded_items.include?(item)
  end
  
  def expand(item)
    @expanded_items.add(item) if item.can_expand?
  end
  
  def collapse(item)
    @expanded_items.delete(item)
  end
  
  def toggle_expand(item)
    if expanded?(item)
      collapse(item)
    else
      expand(item)
    end
  end
  
  def select_item(item)
    @selected_item = item
  end
  
  def change_directory(path)
    @current_directory = path
    @expanded_items.clear
    @selected_item = nil
  end
  
  def clear
    @expanded_items.clear
    @selected_item = nil
  end
end 