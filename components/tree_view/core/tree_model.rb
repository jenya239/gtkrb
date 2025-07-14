class TreeModel
  def get_root_items
    raise NotImplementedError, "Subclasses must implement get_root_items"
  end
  
  def get_children(item)
    raise NotImplementedError, "Subclasses must implement get_children"
  end
  
  def can_expand?(item)
    raise NotImplementedError, "Subclasses must implement can_expand?"
  end
  
  def get_flat_tree
    raise NotImplementedError, "Subclasses must implement get_flat_tree"
  end
  
  def change_directory(path)
    raise NotImplementedError, "Subclasses must implement change_directory"
  end
  
  def current_path
    raise NotImplementedError, "Subclasses must implement current_path"
  end
end 