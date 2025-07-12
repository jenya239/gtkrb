#!/usr/bin/env ruby

require 'gtk4'

# Тестовый скрипт для экспериментов с обновлением Gtk::TreeView
class TreeUpdateTest
  def initialize
    @current_path = Dir.pwd
    @store = Gtk::TreeStore.new(String, String)
    @tree = Gtk::TreeView.new(@store)
    @signal_id = nil
    setup_tree_view
    load_current_directory
  end

  def widget
    scrolled = Gtk::ScrolledWindow.new
    scrolled.set_child(@tree)
    scrolled.set_size_request(300, 400)
    scrolled
  end

  private

  def setup_tree_view
    renderer = Gtk::CellRendererText.new
    column = Gtk::TreeViewColumn.new("Files", renderer, text: 0)
    @tree.append_column(column)
    
    @signal_id = @tree.selection.signal_connect("changed") do |selection|
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
    puts "Selected: #{full_path}"
    
    if full_path == ".."
      puts "Going to parent..."
      go_to_parent
    elsif File.file?(full_path)
      puts "File selected: #{full_path}"
    end
  end

  # ЗАГОТОВКА ДЛЯ ОБНОВЛЕНИЯ ДЕРЕВА
  # TODO: Реализовать безопасное обновление дерева
  def refresh_tree(treeview, build_data_proc)
    puts "=== REFRESH TREE START ==="
    
    # Проблемы, которые нужно решить:
    # 1. Отключить сигналы на время обновления
    # 2. Очистить модель без вызова сигналов
    # 3. Построить новую структуру
    # 4. Включить сигналы обратно
    
    # Варианты решения:
    # - Использовать handler_block/handler_unblock (если доступны)
    # - Отключить/подключить сигналы вручную
    # - Использовать GLib::Idle для отложенного обновления
    # - Создать новую модель и заменить старую
    
    # Пока что просто строим данные в текущей модели
    build_data_proc.call(treeview.model)
    
    puts "=== REFRESH TREE END ==="
  end

  def load_current_directory
    puts "Loading directory: #{@current_path}"
    refresh_tree(@tree, ->(model) { build_tree_data(model) })
    @tree.expand_all
  end

  def build_tree_data(model)
    puts "Building tree data..."
    
    # Добавляем ".." как верхний элемент, если не в корне
    parent_path = File.dirname(@current_path)
    if parent_path != @current_path
      iter = model.append(nil)
      model.set_value(iter, 0, "..")
      model.set_value(iter, 1, "..")
      puts "Added '..' element"
    end
    
    # Добавляем текущую директорию
    build_tree(model, nil, @current_path, File.basename(@current_path))
  end

  # ЗАГОТОВКА ДЛЯ ПЕРЕХОДА В РОДИТЕЛЬСКИЙ КАТАЛОГ
  # TODO: Реализовать безопасный переход
  def go_to_parent
    parent_path = File.dirname(@current_path)
    return if parent_path == @current_path
    
    puts "Changing from #{@current_path} to #{parent_path}"
    @current_path = parent_path
    # TODO: Вызвать безопасное обновление дерева
    # load_current_directory  # Пока отключено из-за проблем с обновлением
  end

  def build_tree(store, parent, path, name)
    return unless Dir.exist?(path)
    
    iter = store.append(parent)
    store.set_value(iter, 0, name)
    store.set_value(iter, 1, path)
    
    Dir.children(path).sort.each do |entry|
      next if entry.start_with?('.')
      full_path = File.join(path, entry)
      
      if File.directory?(full_path)
        build_tree(store, iter, full_path, entry)
      else
        add_file_to_tree(store, iter, entry, full_path)
      end
    end
  end

  def add_file_to_tree(store, parent_iter, name, full_path)
    file_iter = store.append(parent_iter)
    store.set_value(file_iter, 0, name)
    store.set_value(file_iter, 1, full_path)
  end
end

# Создаем тестовое окно
app = Gtk::Application.new("org.example.tree-test", :default_flags)

app.signal_connect "activate" do |application|
  win = Gtk::ApplicationWindow.new(application)
  win.set_title("Tree Update Test")
  win.set_default_size(400, 500)
  
  # Создаем тестовый компонент
  tree_test = TreeUpdateTest.new
  
  # Добавляем кнопку для тестирования обновления
  button = Gtk::Button.new(label: "Test Refresh")
  button.signal_connect("clicked") do
    puts "Button clicked - testing refresh..."
    # TODO: Добавить тестовое обновление
  end
  
  # Layout
  box = Gtk::Box.new(:vertical, 10)
  box.append(button)
  box.append(tree_test.widget)
  
  win.set_child(box)
  win.present
end

puts "Starting Tree Update Test..."
app.run 