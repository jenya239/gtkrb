require_relative '../lib/ui/file_tree_panel'

puts "=== Тест навигации по директориям ==="

# Создаем файловое дерево
tree = FileTreePanel.new(Dir.pwd)

# Проверяем начальный путь
puts "Начальный путь: #{tree.current_path}"

# Тестируем callback для выбора файла
file_selected = nil
tree.on_file_selected do |path|
  file_selected = path
  puts "Выбран файл: #{path}"
end

# Тестируем callback для изменения директории
directory_changed = nil
tree.on_directory_changed do |path|
  directory_changed = path
  puts "Изменена директория: #{path}"
end

# Тестируем смену директории
puts "\nТестирование смены директории на /tmp:"
tree.change_directory("/tmp")
puts "Новый путь: #{tree.current_path}"

# Тестируем возврат в исходную директорию
puts "\nВозврат в исходную директорию:"
tree.change_directory(Dir.pwd)
puts "Путь после возврата: #{tree.current_path}"

puts "\n=== Тест завершен ==="
puts "Callbacks работают: #{!file_selected.nil? || !directory_changed.nil? ? 'ДА' : 'НЕТ'}" 