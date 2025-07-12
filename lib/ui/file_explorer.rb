require_relative 'widgets/simple_custom_tree'

class FileExplorer
  def initialize
    @tree = SimpleCustomTree.new
  end

  def widget
    @tree
  end

  def on_file_selected(&block)
    @tree.define_singleton_method(:open_file) do |path|
      block.call(path) if block
    end
  end
end 