require_relative 'file_tree_manager'
require_relative 'tree_view'

class FileTreeAdapter < TreeDataSource
  def initialize(root_path = Dir.pwd)
    @manager = FileTreeManager.new(root_path)
  end
  
  def get_root_items
    @manager.get_root_items
  end
  
  def get_children(parent_item)
    @manager.get_children(parent_item)
  end
  
  def can_expand?(item)
    @manager.can_expand?(item)
  end
  
  def change_directory(path)
    @manager.change_directory(path)
  end
  
  def current_path
    @manager.state.current_directory
  end
  
  def toggle_expand(item)
    @manager.toggle_expand(item)
  end
  
  def select_item(item)
    @manager.select_item(item)
  end
  
  def get_flat_tree
    @manager.get_flat_tree
  end
  
  def state
    @manager.state
  end
end 