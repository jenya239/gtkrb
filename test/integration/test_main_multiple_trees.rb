#!/usr/bin/env ruby

# Тест интеграции множественных файловых деревьев в основное приложение

require 'gtk3'
require_relative 'lib/ui/main_window'

class TestMainMultipleTrees
  def initialize
    @main_window = MainWindow.new
    @main_window.signal_connect("destroy") { Gtk.main_quit }
    
    setup_test_directories
    show_usage
  end

  def setup_test_directories
    # Создаем дополнительные файловые деревья для тестирования
    test_directories = [
      File.expand_path("~/Documents"),
      File.expand_path("~/"),
      "/tmp"
    ].select { |dir| Dir.exist?(dir) }
    
    puts "Creating additional file trees..."
    test_directories.each do |dir|
      tree_id = @main_window.create_additional_file_tree(dir)
      puts "Created tree #{tree_id} for #{dir}"
    end
    
    puts "File trees created: #{@main_window.get_file_trees.size}"
  end

  def show_usage
    puts "\n=== Multiple File Trees Integration Test ==="
    puts "Main window is now running with multiple file trees"
    puts
    puts "Usage:"
    puts "- Main file tree is in the left panel"
    puts "- Additional file trees are in separate windows"
    puts "- Click files in any tree to open them in the main editor"
    puts "- Ctrl+Shift+T - create new file tree"
    puts "- Files from all trees open in the same editor"
    puts "- Use normal editor shortcuts (Ctrl+S, Ctrl+Shift+E, etc.)"
    puts "=========================================\n"
  end

  def run
    @main_window.show_all
    Gtk.main
  end
end

# Запуск теста
if __FILE__ == $0
  test = TestMainMultipleTrees.new
  test.run
end 