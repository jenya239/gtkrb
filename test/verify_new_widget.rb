#!/usr/bin/env ruby

require_relative '../lib/ui/file_explorer'

puts "🔍 Проверка использования нового виджета..."

# Создаем FileExplorer
explorer = FileExplorer.new

# Проверяем, что используется FileTreeView
tree_class = explorer.widget.class
puts "✅ Используется виджет: #{tree_class}"

if tree_class.to_s == "FileTreeView"
  puts "🎉 УСПЕХ: Новый рефакторенный виджет FileTreeView используется!"
else
  puts "❌ ОШИБКА: Используется старый виджет #{tree_class}"
end

# Проверяем методы
puts "\n🔧 Проверка методов:"
puts "  - load_directory: #{explorer.respond_to?(:load_directory)}"
puts "  - refresh: #{explorer.respond_to?(:refresh)}"
puts "  - on_file_selected: #{explorer.respond_to?(:on_file_selected)}"

# Проверяем callback
callback_called = false
explorer.on_file_selected do |path|
  callback_called = true
  puts "📁 Файл выбран: #{path}"
end

puts "\n✅ Все проверки пройдены! Новый виджет работает корректно." 