require_relative 'widgets/file_tree_view'

class FileExplorer
  def initialize
    @tree = FileTreeView.new
    @tree.load_directory(Dir.pwd)
  end

  def widget
    @tree
  end

  def on_file_selected(&block)
    @tree.on_file_selected do |path|
      block.call(path) if block
    end
  end
  
  def refresh
    @tree.refresh
  end
  
  def load_directory(path)
    @tree.load_directory(path)
  end
end 