require 'gtk4'

class FileExplorer
  def initialize
    @store = Gtk::TreeStore.new(String, String)
    @tree = Gtk::TreeView.new(@store)
    setup_tree_view
    load_project_structure
  end

  def widget
    scrolled = Gtk::ScrolledWindow.new
    scrolled.set_child(@tree)
    scrolled.set_size_request(250, -1)
    scrolled
  end

  def on_file_selected(&block)
    @on_file_selected = block
  end

  private

  def setup_tree_view
    renderer = Gtk::CellRendererText.new
    column = Gtk::TreeViewColumn.new("Files", renderer, text: 0)
    @tree.append_column(column)
    
    @tree.selection.signal_connect("changed") do |selection|
      handle_selection_change(selection)
    end
  end

  def handle_selection_change(selection)
    selected_rows = selection.selected_rows
    return if selected_rows.empty?
    
    path = selected_rows.first.first
    iter = @store.get_iter(path)
    return unless iter
    
    full_path = @store.get_value(iter, 1)
    @on_file_selected&.call(full_path) if File.file?(full_path)
  end

  def load_project_structure
    root_path = Dir.pwd
    build_tree(nil, root_path, File.basename(root_path))
    @tree.expand_all
  end

  def build_tree(parent, path, name)
    return unless Dir.exist?(path)
    
    iter = @store.append(parent)
    @store.set_value(iter, 0, name)
    @store.set_value(iter, 1, path)
    
    Dir.children(path).sort.each do |entry|
      next if entry.start_with?('.')
      full_path = File.join(path, entry)
      
      if File.directory?(full_path)
        build_tree(iter, full_path, entry)
      else
        add_file_to_tree(iter, entry, full_path)
      end
    end
  end

  def add_file_to_tree(parent_iter, name, full_path)
    file_iter = @store.append(parent_iter)
    @store.set_value(file_iter, 0, name)
    @store.set_value(file_iter, 1, full_path)
  end
end 