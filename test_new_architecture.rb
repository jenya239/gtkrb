#!/usr/bin/env ruby

require 'gtk3'

begin
  puts "Loading new_editor_manager..."
  require_relative 'lib/ui/new_editor_manager'
  puts "new_editor_manager loaded successfully"
rescue => e
  puts "Error loading new_editor_manager: #{e.message}"
  puts e.backtrace
  exit 1
end

begin
  # Инициализация GTK
  puts "Initializing GTK..."
  Gtk.init
  puts "GTK initialized"

  # Создаем окно
  puts "Creating window..."
  window = Gtk::Window.new
  window.set_title("New Architecture Test")
  window.set_default_size(1200, 800)
  puts "Window created"

  # Создаем новый editor manager
  puts "Creating editor manager..."
  editor_manager = NewEditorManager.new
  puts "Editor manager created"

  # Добавляем в окно
  puts "Adding widget to window..."
  window.add(editor_manager.widget)
  puts "Widget added to window"

  # Загружаем файлы из аргументов командной строки
  if ARGV.length > 0
    puts "Loading files: #{ARGV.join(', ')}"
    editor_manager.load_multiple_files(ARGV)
    puts "Files loaded"
  else
    puts "No files specified - starting with empty editor"
  end

  # Обработка закрытия окна
  window.signal_connect("destroy") { Gtk.main_quit }

  # Показываем окно
  puts "Showing window..."
  window.show_all
  puts "Window shown"

  # Запускаем GTK event loop
  puts "Starting GTK main loop..."
  Gtk.main
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace
  exit 1
end 