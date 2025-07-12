#!/usr/bin/env ruby

require 'gtk4'

# Простой тест обновления дерева
store = Gtk::TreeStore.new(String)
tree = Gtk::TreeView.new(store)

# Настройка дерева
renderer = Gtk::CellRendererText.new
column = Gtk::TreeViewColumn.new("Files", renderer, text: 0)
tree.append_column(column)

# Сигнал выбора
tree.selection.signal_connect("changed") do |selection|
  selected = selection.selected_rows
  return if selected.empty?
  
  path = selected.first.first
  iter = store.get_iter(path)
  return unless iter
  
  value = store.get_value(iter, 0)
  puts "Selected: #{value}"
  
  if value == ".."
    puts "Going to parent..."
    # TODO: Обновить дерево
  end
end

# Заполнение данными
iter = store.append(nil)
store.set_value(iter, 0, "..")

iter = store.append(nil)
store.set_value(iter, 0, "file1.txt")

iter = store.append(nil)
store.set_value(iter, 0, "file2.txt")

# Приложение
app = Gtk::Application.new("org.test.simple", :default_flags)

app.signal_connect "activate" do |application|
  # Окно
  win = Gtk::ApplicationWindow.new(application)
  win.set_title("Simple Tree Test")
  win.set_default_size(300, 400)

  button = Gtk::Button.new(label: "Refresh")
  button.signal_connect("clicked") do
    puts "Refreshing..."
    # TODO: Обновить дерево
  end

  box = Gtk::Box.new(:vertical, 10)
  box.append(button)
  box.append(tree)

  win.set_child(box)
  win.present
end

app.run 