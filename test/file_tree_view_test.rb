#!/usr/bin/env ruby

require 'gtk4'
require_relative '../lib/ui/widgets/file_tree_view'

# Тестовое приложение для демонстрации нового FileTreeView
app = Gtk::Application.new("org.example.file-tree-view", :default_flags)

app.signal_connect "activate" do |application|
  win = Gtk::ApplicationWindow.new(application)
  win.set_title("File Tree View - Refactored")
  win.set_default_size(600, 500)
  
  # Создаем основной layout
  main_box = Gtk::Box.new(:horizontal, 10)
  win.set_child(main_box)
  
  # Левая панель - обычный файловый обозреватель
  left_panel = Gtk::Box.new(:vertical, 5)
  left_label = Gtk::Label.new("File System")
  left_label.set_margin_start(10)
  left_label.set_margin_top(10)
  left_panel.append(left_label)
  
  file_tree = FileTreeView.new
  file_tree.load_directory(Dir.pwd)
  file_tree.on_file_selected do |path|
    puts "File selected: #{path}"
  end
  left_panel.append(file_tree)
  
  # Правая панель - Git обозреватель (если это Git репозиторий)
  right_panel = Gtk::Box.new(:vertical, 5)
  right_label = Gtk::Label.new("Git Repository")
  right_label.set_margin_start(10)
  right_label.set_margin_top(10)
  right_panel.append(right_label)
  
  git_tree = FileTreeView.new(GitDataProvider.new(Dir.pwd))
  git_tree.load_directory(Dir.pwd)
  git_tree.on_file_selected do |path|
    puts "Git item selected: #{path}"
  end
  right_panel.append(git_tree)
  
  # Добавляем панели в основной layout
  main_box.append(left_panel)
  main_box.append(right_panel)
  
  # Кнопки управления
  button_box = Gtk::Box.new(:horizontal, 5)
  button_box.set_margin_start(10)
  button_box.set_margin_end(10)
  button_box.set_margin_bottom(10)
  
  refresh_btn = Gtk::Button.new(label: "Refresh")
  refresh_btn.signal_connect("clicked") do
    file_tree.refresh
    git_tree.refresh
  end
  
  switch_btn = Gtk::Button.new(label: "Switch to Git")
  switch_btn.signal_connect("clicked") do
    file_tree.set_data_provider(GitDataProvider.new(Dir.pwd))
  end
  
  button_box.append(refresh_btn)
  button_box.append(switch_btn)
  
  # Добавляем кнопки в основное окно
  main_box.append(button_box)
  win.set_child(main_box)
  
  win.present
end

app.run 