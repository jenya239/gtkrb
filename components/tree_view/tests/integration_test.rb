#!/usr/bin/env ruby

require_relative '../src/file_tree_adapter'
require_relative '../src/tree_view'

# Вспомогательные классы для тестирования
class MockTreeDataSource < TreeDataSource
  def get_root_items
    [
      MockItem.new('test1', :directory),
      MockItem.new('test2', :file)
    ]
  end
  
  def get_children(item)
    []
  end
  
  def can_expand?(item)
    item.type == :directory
  end
end

class MockItem
  attr_reader :name, :type, :path
  
  def initialize(name, type)
    @name = name
    @type = type
    @path = "/mock/#{name}"
  end
  
  def directory?
    @type == :directory
  end
  
  def file?
    @type == :file
  end
  
  def can_expand?
    directory?
  end
end

class IntegrationTest
  def run_tests
    puts "=== Интеграционный тест FileTreeAdapter + TreeView ==="
    
    test_adapter
    test_adapter_with_mock_tree_view
    
    puts "✅ Все интеграционные тесты пройдены успешно!"
  end
  
  private
  
  def test_adapter
    puts "📂 Тестирование FileTreeAdapter..."
    
    adapter = FileTreeAdapter.new(Dir.pwd)
    
    # Тестируем базовую функциональность
    root_items = adapter.get_root_items
    assert !root_items.empty?, "Root items не должны быть пустыми"
    
    dir_item = root_items.find { |item| item.directory? && !item.parent_directory? }
    assert dir_item, "Должна быть директория"
    
    assert adapter.can_expand?(dir_item), "Директория должна раскрываться"
    
    children = adapter.get_children(dir_item)
    assert children.is_a?(Array), "Дети должны быть массивом"
    
    # Тестируем состояние
    assert !adapter.state.expanded?(dir_item), "Директория не должна быть раскрыта изначально"
    
    adapter.toggle_expand(dir_item)
    assert adapter.state.expanded?(dir_item), "Директория должна быть раскрыта после toggle"
    
    # Тестируем плоское дерево
    flat_tree = adapter.get_flat_tree
    assert flat_tree.is_a?(Array), "Плоское дерево должно быть массивом"
    assert flat_tree.all? { |item, level| item.respond_to?(:name) && level.is_a?(Integer) }, "Элементы должны иметь правильный формат"
    
    # Проверяем, что раскрытая директория содержит детей
    levels = flat_tree.map { |item, level| level }
    assert levels.include?(1), "Должны быть элементы уровня 1"
    
    puts "✅ FileTreeAdapter работает корректно"
  end
  
  def test_adapter_with_mock_tree_view
    puts "🌳 Тестирование интеграции с TreeView..."
    
    # Сравниваем интерфейсы
    adapter = FileTreeAdapter.new(Dir.pwd)
    mock_source = MockTreeDataSource.new
    
    # Оба должны реализовывать один интерфейс
    [:get_root_items, :get_children, :can_expand?].each do |method|
      assert adapter.respond_to?(method), "Adapter должен реализовывать #{method}"
      assert mock_source.respond_to?(method), "MockSource должен реализовывать #{method}"
    end
    
    # Проверяем, что adapter возвращает корректные типы
    root_items = adapter.get_root_items
    assert root_items.all? { |item| item.respond_to?(:name) && item.respond_to?(:type) }, "Все элементы должны иметь name и type"
    
    puts "✅ Интеграция с TreeView корректна"
  end
  
  def assert(condition, message)
    raise "Assertion failed: #{message}" unless condition
  end
end

# Запускаем тесты
if __FILE__ == $0
  test = IntegrationTest.new
  test.run_tests
end 