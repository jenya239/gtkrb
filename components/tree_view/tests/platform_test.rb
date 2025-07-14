#!/usr/bin/env ruby

# Простой тест для платформы GTK3
# Этот тест проверяет что все компоненты создаются без ошибок

require_relative '../platform/gtk3/gtk3_tree_widget'

puts "Testing Platform Layer (GTK3)..."

begin
  # Создаем виджет
  widget = GTK3TreeWidget.new
  puts "✓ GTK3TreeWidget created successfully"
  
  # Проверяем основные методы
  puts "✓ Current path: #{widget.current_path}"
  puts "✓ Tree controller: #{widget.tree_controller.class}"
  puts "✓ Renderer: #{widget.renderer.class}"
  puts "✓ Input controller: #{widget.input_controller.class}"
  
  # Проверяем коллбеки
  widget.on_item_selected { |item| puts "Item selected: #{item}" }
  widget.on_item_activated { |item| puts "Item activated: #{item}" }
  widget.on_directory_changed { |path| puts "Directory changed: #{path}" }
  
  puts "✓ All callbacks registered successfully"
  
  puts "\n✅ Platform Layer test passed!"
  
rescue => e
  puts "\n❌ Platform Layer test failed: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end 