require_relative '../lib/ui/panel_type_manager'

# Упрощенная мок-панель которая имитирует реальные методы EditorPane
class RealEditorPaneMock
  def initialize(terminal_mode: false, file_tree_mode: false, current_file: nil, is_new_file: false)
    @terminal_mode = terminal_mode
    @file_tree_mode = file_tree_mode
    @current_file = current_file
    @is_new_file = is_new_file
  end
  
  def terminal_mode?
    @terminal_mode
  end
  
  def file_tree_mode?
    @file_tree_mode
  end
  
  def current_file
    @current_file
  end
  
  def is_new_file
    @is_new_file
  end
end

# Интеграционный тест
puts "=== Интеграционный тест PanelTypeManager ==="

# Создаем реалистичные панели
editor_with_file = RealEditorPaneMock.new(current_file: "test.rb")
editor_new_file = RealEditorPaneMock.new(is_new_file: true)
file_tree_panel = RealEditorPaneMock.new(file_tree_mode: true)
terminal_panel = RealEditorPaneMock.new(terminal_mode: true)

panes = [editor_with_file, editor_new_file, file_tree_panel, terminal_panel]
manager = PanelTypeManager.new(panes)

# Тест 1: Определение типов
puts "\n--- Тест определения типов ---"
puts "Редактор с файлом: #{manager.get_panel_type(editor_with_file)}"
puts "Новый редактор: #{manager.get_panel_type(editor_new_file)}"
puts "Файловое дерево: #{manager.get_panel_type(file_tree_panel)}"
puts "Терминал: #{manager.get_panel_type(terminal_panel)}"

# Тест 2: Поиск лучшего редактора
puts "\n--- Тест поиска лучшего редактора ---"
best_editor = manager.find_best_editor_panel
puts "Лучший редактор: #{best_editor == editor_with_file ? 'с файлом' : 'новый'}"

# Тест 3: Статистика
puts "\n--- Статистика панелей ---"
stats = manager.get_panel_stats
puts "Всего: #{stats[:total]}, Редакторов: #{stats[:editors]}, Деревьев: #{stats[:file_trees]}, Терминалов: #{stats[:terminals]}"

# Тест 4: Нужна ли новая панель?
puts "\n--- Тест создания новой панели ---"
puts "Нужна новая панель? #{manager.should_create_new_panel_for_file? ? 'НЕТ' : 'ДА'}"

# Тест 5: Только файловые деревья
only_trees = [file_tree_panel]
manager_trees = PanelTypeManager.new(only_trees)
puts "Только деревья - нужна новая панель? #{manager_trees.should_create_new_panel_for_file? ? 'ДА' : 'НЕТ'}"

puts "\n=== Тест завершен ===" 