#!/usr/bin/env ruby

require 'gtk3'
require_relative 'lib/ui/main_window'

# Создаем главное окно
window = MainWindow.new

# Обрабатываем аргументы командной строки
if ARGV.length > 0
  files = []
  directories = []
  
  ARGV.each do |arg|
    if File.directory?(arg)
      directories << arg
    elsif File.file?(arg)
      files << arg
    else
      puts "Warning: #{arg} is not a valid file or directory"
    end
  end
  
  if directories.any?
    puts "Loading directories: #{directories.join(', ')}"
    window.editor_manager.load_directories(directories)
  elsif files.any?
    puts "Loading files: #{files.join(', ')}"
    window.editor_manager.load_multiple_files(files)
  end
else
  # Загружаем файл по умолчанию, если указан
  default_file = 'README.md'
  if File.exist?(default_file)
    window.editor_manager.load_file(default_file)
  end
end

# Показываем окно
window.show_all
window.signal_connect('destroy') { Gtk.main_quit }

# Запускаем главный цикл
Gtk.main 