require_relative 'tree_model'
require_relative '../src/file_tree_item'
require_relative '../src/file_tree_state'

class FileTreeModel < TreeModel
  attr_reader :state
  
  def initialize(root_path = Dir.pwd)
    @state = FileTreeState.new(root_path)
  end
  
  def get_root_items
    build_items_for_directory(@state.current_directory, include_parent: true)
  end
  
  def get_children(item)
    return [] unless item.can_expand?
    build_items_for_directory(item.path, include_parent: false)
  end
  
  def can_expand?(item)
    item.can_expand?
  end
  
  def get_flat_tree
    items = []
    root_items = get_root_items
    
    root_items.each do |item|
      add_item_to_flat_tree(items, item, 0)
    end
    
    items
  end
  
  def change_directory(path)
    @state.change_directory(path)
  end
  
  def current_path
    @state.current_directory
  end
  
  private
  
  def add_item_to_flat_tree(items, item, level)
    items << [item, level]
    
    if @state.expanded?(item) && item.can_expand?
      children = get_children(item)
      children.each do |child|
        add_item_to_flat_tree(items, child, level + 1)
      end
    end
  end
  
  def build_items_for_directory(dir_path, include_parent: false)
    items = []
    
    # Добавляем родительскую директорию
    if include_parent
      parent_path = File.dirname(dir_path)
      if parent_path != dir_path
        items << FileTreeItem.new(
          name: '..',
          path: parent_path,
          type: :parent
        )
      end
    end
    
    # Получаем файлы и директории
    begin
      entries = Dir.children(dir_path)
      dirs, files = entries.partition { |e| File.directory?(File.join(dir_path, e)) }
      
      # Сортируем по алфавиту без учета регистра
      dirs_sorted = dirs.sort_by(&:downcase)
      files_sorted = files.sort_by(&:downcase)
      
      # Добавляем директории
      dirs_sorted.each do |entry|
        full_path = File.join(dir_path, entry)
        items << FileTreeItem.new(
          name: entry,
          path: full_path,
          type: :directory
        )
      end
      
      # Добавляем файлы
      files_sorted.each do |entry|
        full_path = File.join(dir_path, entry)
        items << FileTreeItem.new(
          name: entry,
          path: full_path,
          type: :file
        )
      end
    rescue => e
      # Игнорируем ошибки чтения директории
    end
    
    items
  end
end 