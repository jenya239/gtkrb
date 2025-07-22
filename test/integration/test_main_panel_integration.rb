#!/usr/bin/env ruby

# Тест интеграции панельной системы в основное приложение

require 'gtk3'
require_relative 'lib/ui/main_window'

puts "Testing Panel Integration in Main Application"
puts "============================================="
puts
puts "Features to test:"
puts "- Basic editor functionality"
puts "- Panel switching with buttons (📁📄🖥️)"
puts "- Keyboard shortcuts:"
puts "  - Ctrl+N - new file"
puts "  - Ctrl+S - save file"
puts "  - Ctrl+O - open file"
puts "  - Ctrl+Shift+E - split horizontal"
puts "  - Ctrl+Shift+O - split vertical"
puts "  - Ctrl+W - close panel"
puts "  - Ctrl+Shift+F - convert to file manager"
puts "  - Ctrl+Shift+T - convert to terminal"
puts
puts "Starting main application with panel system..."

# Создаем и запускаем основное приложение
main_window = MainWindow.new
main_window.signal_connect("destroy") { Gtk.main_quit }
main_window.show_all

Gtk.main 