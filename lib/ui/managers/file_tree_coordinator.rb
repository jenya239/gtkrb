class FileTreeCoordinator
  def initialize(editor_manager)
    @editor_manager = editor_manager
    @file_trees = {}
  end
  
  def register_file_tree(tree_id, root_dir)
    @file_trees[tree_id] = {
      root_dir: root_dir,
      tree_id: tree_id
    }
  end
  
  def unregister_file_tree(tree_id)
    @file_trees.delete(tree_id)
  end
  
  def handle_file_selected(file_path, from_tree_id = nil)
    # Открыть файл в активном редакторе через EditorManager
    @editor_manager.load_file(file_path)
  end
  
  def get_file_trees
    @file_trees
  end
  
  # Compatibility methods for PanelManager interface
  def create_editor_panel
    @editor_manager.create_pane
  end
  
  def active_panel
    @editor_manager.active_pane
  end
  
  def panels
    @editor_manager.panes
  end
  
  private
  
  def find_active_editor_panel
    # EditorManager уже управляет активным редактором
    @editor_manager.active_pane
  end
end 