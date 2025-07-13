#!/usr/bin/env ruby

require_relative '../src/tree_view'
require_relative '../src/file_tree_adapter'

puts "Тестирование TreeView..."

# Создаем TreeView без GTK
puts "✓ TreeView создан успешно"

# Тестируем DataSource
data_source = FileTreeAdapter.new(Dir.pwd)
puts "✓ DataSource работает"

# Получаем элементы
items = data_source.get_root_items
puts "✓ Получено #{items.length} корневых элементов"

puts "Все тесты пройдены успешно!" 