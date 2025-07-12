#!/usr/bin/env ruby

# Интерфейс для провайдера данных дерева
class TreeDataProvider
  def get_items(path)
    raise NotImplementedError, "#{self.class} must implement get_items"
  end
  
  def get_children(item)
    raise NotImplementedError, "#{self.class} must implement get_children"
  end
  
  def can_expand?(item)
    raise NotImplementedError, "#{self.class} must implement can_expand?"
  end
  
  def get_icon(item)
    raise NotImplementedError, "#{self.class} must implement get_icon"
  end
  
  def get_text(item)
    raise NotImplementedError, "#{self.class} must implement get_text"
  end
end

# Реализация для файловой системы
class FileSystemDataProvider < TreeDataProvider
  def get_items(path)
    items = []
    
    # Родительская директория
    parent = File.dirname(path)
    if parent != path
      items << TreeItem.new(name: "..", path: "..", type: :parent, level: 0)
    end
    
    # Текущая директория
    items << TreeItem.new(name: File.basename(path), path: path, type: :current, level: 0)
    
    # Содержимое директории
    Dir.children(path).sort.each do |entry|
      next if entry.start_with?('.')
      full_path = File.join(path, entry)
      
      if File.directory?(full_path)
        items << TreeItem.new(name: entry, path: full_path, type: :directory, level: 1)
      else
        items << TreeItem.new(name: entry, path: full_path, type: :file, level: 1)
      end
    end
    
    items
  end
  
  def get_children(item)
    return nil unless item.directory?
    return nil if item.type == :parent
    
    get_items(item.path)
  end
  
  def can_expand?(item)
    item.directory? && item.type != :parent
  end
  
  def get_icon(item)
    case item.type
    when :parent then TreeViewTheme::ICON_UP
    when :directory, :current then TreeViewTheme::ICON_FOLDER
    else TreeViewTheme::ICON_FILE
    end
  end
  
  def get_text(item)
    item.name
  end
end

# Реализация для Git репозитория
class GitDataProvider < TreeDataProvider
  def initialize(repo_path)
    @repo_path = repo_path
  end
  
  def get_items(path)
    items = []
    
    # Git статус
    items << TreeItem.new(name: "📊 Status", path: "git:status", type: :git_status, level: 0)
    items << TreeItem.new(name: "🌿 Branches", path: "git:branches", type: :git_branches, level: 0)
    items << TreeItem.new(name: "📝 Commits", path: "git:commits", type: :git_commits, level: 0)
    
    # Файлы с учетом Git
    get_git_files(path).each do |file|
      items << file
    end
    
    items
  end
  
  def get_children(item)
    case item.type
    when :git_branches then get_branches
    when :git_commits then get_commits
    else nil
    end
  end
  
  def can_expand?(item)
    [:git_branches, :git_commits, :directory].include?(item.type)
  end
  
  def get_icon(item)
    case item.type
    when :git_status then "📊"
    when :git_branches then "🌿"
    when :git_commits then "📝"
    when :directory then TreeViewTheme::ICON_FOLDER
    else TreeViewTheme::ICON_FILE
    end
  end
  
  def get_text(item)
    item.name
  end
  
  private
  
  def get_git_files(path)
    # Упрощенная реализация - можно расширить
    []
  end
  
  def get_branches
    # Упрощенная реализация
    []
  end
  
  def get_commits
    # Упрощенная реализация
    []
  end
end 