#!/usr/bin/env ruby

require 'tmpdir'
require 'fileutils'
require_relative '../src/file_tree_manager'
require_relative '../src/file_tree_item'
require_relative '../src/file_tree_state'

class FileTreeManagerTest
  def initialize
    @test_dir = nil
    @manager = nil
  end
  
  def run_tests
    puts "=== Тестирование FileTreeManager ==="
    
    setup_test_directory
    
    test_initialization
    test_root_items
    test_sorting
    test_children
    test_expansion
    test_flat_tree
    test_directory_navigation
    test_item_types
    
    cleanup_test_directory
    
    puts "✅ Все тесты пройдены успешно!"
  end
  
  private
  
  def setup_test_directory
    @test_dir = Dir.mktmpdir('file_tree_test')
    puts "🔧 Создан тестовый каталог: #{@test_dir}"
    
    # Создаем структуру каталогов для тестов
    FileUtils.mkdir_p(File.join(@test_dir, 'lib', 'core'))
    FileUtils.mkdir_p(File.join(@test_dir, 'lib', 'ui'))
    FileUtils.mkdir_p(File.join(@test_dir, 'test'))
    FileUtils.mkdir_p(File.join(@test_dir, 'assets'))
    
    # Создаем файлы
    File.write(File.join(@test_dir, 'README.md'), 'test')
    File.write(File.join(@test_dir, 'app.rb'), 'test')
    File.write(File.join(@test_dir, 'lib', 'core', 'manager.rb'), 'test')
    File.write(File.join(@test_dir, 'lib', 'ui', 'window.rb'), 'test')
    File.write(File.join(@test_dir, 'test', 'test_file.rb'), 'test')
    
    @manager = FileTreeManager.new(@test_dir)
  end
  
  def cleanup_test_directory
    FileUtils.rm_rf(@test_dir) if @test_dir
    puts "🧹 Удален тестовый каталог"
  end
  
  def test_initialization
    assert @manager.state.current_directory == @test_dir, "Неверная текущая директория"
    assert @manager.state.expanded_items.empty?, "Expanded items должны быть пустыми"
    assert @manager.state.selected_item.nil?, "Selected item должен быть nil"
    puts "✅ Тест инициализации пройден"
  end
  
  def test_root_items
    items = @manager.get_root_items
    
    # Проверяем, что есть элементы
    assert !items.empty?, "Root items не должны быть пустыми"
    
    # Проверяем наличие родительской директории
    parent_item = items.find { |item| item.parent_directory? }
    assert parent_item, "Должен быть элемент родительской директории"
    assert parent_item.name == '..', "Имя родительской директории должно быть '..'"
    
    # Проверяем наличие созданных элементов
    names = items.map(&:name)
    assert names.include?('lib'), "Должна быть директория 'lib'"
    assert names.include?('test'), "Должна быть директория 'test'"
    assert names.include?('README.md'), "Должен быть файл 'README.md'"
    assert names.include?('app.rb'), "Должен быть файл 'app.rb'"
    
    puts "✅ Тест root items пройден"
  end
  
  def test_sorting
    items = @manager.get_root_items
    
    # Убираем родительскую директорию для проверки сортировки
    items_without_parent = items.reject(&:parent_directory?)
    
    # Разделяем на директории и файлы
    dirs = items_without_parent.select(&:directory?)
    files = items_without_parent.select(&:file?)
    
    # Проверяем, что директории идут первыми
    combined = dirs + files
    actual_order = items_without_parent.map(&:name)
    expected_order = combined.map(&:name)
    
    assert actual_order == expected_order, "Неверный порядок сортировки: #{actual_order} != #{expected_order}"
    
    # Проверяем алфавитную сортировку директорий
    dir_names = dirs.map(&:name)
    sorted_dirs = dir_names.sort_by(&:downcase)
    assert dir_names == sorted_dirs, "Директории не отсортированы: #{dir_names} != #{sorted_dirs}"
    
    # Проверяем алфавитную сортировку файлов
    file_names = files.map(&:name)
    sorted_files = file_names.sort_by(&:downcase)
    assert file_names == sorted_files, "Файлы не отсортированы: #{file_names} != #{sorted_files}"
    
    puts "✅ Тест сортировки пройден"
  end
  
  def test_children
    items = @manager.get_root_items
    lib_item = items.find { |item| item.name == 'lib' }
    
    assert lib_item, "Должен быть элемент 'lib'"
    assert lib_item.can_expand?, "Элемент 'lib' должен раскрываться"
    
    children = @manager.get_children(lib_item)
    assert !children.empty?, "Дети 'lib' не должны быть пустыми"
    
    names = children.map(&:name)
    assert names.include?('core'), "Должна быть поддиректория 'core'"
    assert names.include?('ui'), "Должна быть поддиректория 'ui'"
    
    # Проверяем, что нет родительской директории в детях
    assert !children.any?(&:parent_directory?), "В детях не должно быть родительской директории"
    
    puts "✅ Тест children пройден"
  end
  
  def test_expansion
    items = @manager.get_root_items
    lib_item = items.find { |item| item.name == 'lib' }
    
    # Проверяем начальное состояние
    assert !@manager.state.expanded?(lib_item), "Элемент не должен быть раскрыт изначально"
    
    # Раскрываем
    @manager.toggle_expand(lib_item)
    assert @manager.state.expanded?(lib_item), "Элемент должен быть раскрыт после toggle"
    
    # Сворачиваем
    @manager.toggle_expand(lib_item)
    assert !@manager.state.expanded?(lib_item), "Элемент должен быть свернут после второго toggle"
    
    # Проверяем прямые методы
    @manager.state.expand(lib_item)
    assert @manager.state.expanded?(lib_item), "Элемент должен быть раскрыт после expand"
    
    @manager.state.collapse(lib_item)
    assert !@manager.state.expanded?(lib_item), "Элемент должен быть свернут после collapse"
    
    puts "✅ Тест expansion пройден"
  end
  
  def test_flat_tree
    items = @manager.get_root_items
    lib_item = items.find { |item| item.name == 'lib' }
    
    # Без раскрытия
    flat_tree = @manager.get_flat_tree
    assert flat_tree.all? { |item, level| level == 0 }, "Все элементы должны быть на уровне 0"
    
    # С раскрытием
    @manager.toggle_expand(lib_item)
    flat_tree = @manager.get_flat_tree
    
    # Проверяем наличие элементов разных уровней
    levels = flat_tree.map { |item, level| level }
    assert levels.include?(0), "Должны быть элементы уровня 0"
    assert levels.include?(1), "Должны быть элементы уровня 1"
    
    # Проверяем порядок - lib должен быть перед своими детьми
    lib_index = flat_tree.find_index { |item, level| item.name == 'lib' }
    core_index = flat_tree.find_index { |item, level| item.name == 'core' }
    ui_index = flat_tree.find_index { |item, level| item.name == 'ui' }
    
    assert lib_index < core_index, "lib должен быть перед core"
    assert core_index < ui_index, "core должен быть перед ui"
    assert lib_index + 1 == core_index, "core должен быть сразу после lib"
    
    puts "✅ Тест flat tree пройден"
  end
  
  def test_directory_navigation
    items = @manager.get_root_items
    lib_item = items.find { |item| item.name == 'lib' }
    
    # Переходим в директорию
    @manager.change_directory(lib_item.path)
    
    assert @manager.state.current_directory == lib_item.path, "Текущая директория должна измениться"
    assert @manager.state.expanded_items.empty?, "Expanded items должны очиститься"
    assert @manager.state.selected_item.nil?, "Selected item должен очиститься"
    
    # Проверяем новые root items
    new_items = @manager.get_root_items
    names = new_items.map(&:name)
    assert names.include?('..'), "Должна быть родительская директория"
    assert names.include?('core'), "Должна быть директория 'core'"
    assert names.include?('ui'), "Должна быть директория 'ui'"
    
    puts "✅ Тест directory navigation пройден"
  end
  
  def test_item_types
    # Возвращаемся в корневую директорию после предыдущих тестов
    @manager.change_directory(@test_dir)
    
    items = @manager.get_root_items
    
    parent_item = items.find(&:parent_directory?)
    dir_item = items.find { |item| item.directory? && !item.parent_directory? }
    file_item = items.find(&:file?)
    
    puts "Найденные элементы:"
    items.each { |item| puts "  #{item.name} (#{item.type})" }
    
    assert parent_item, "Должен быть parent item"
    assert dir_item, "Должен быть directory item"
    assert file_item, "Должен быть file item"
    
    assert parent_item.parent_directory?, "Parent item должен быть parent_directory?"
    assert !parent_item.can_expand?, "Parent item не должен раскрываться"
    
    assert dir_item.directory?, "Directory item должен быть directory?"
    assert dir_item.can_expand?, "Directory item должен раскрываться"
    
    assert file_item.file?, "File item должен быть file?"
    assert !file_item.can_expand?, "File item не должен раскрываться"
    
    puts "✅ Тест item types пройден"
  end
  
  def assert(condition, message)
    raise "Assertion failed: #{message}" unless condition
  end
end

# Запускаем тесты
if __FILE__ == $0
  test = FileTreeManagerTest.new
  test.run_tests
end 