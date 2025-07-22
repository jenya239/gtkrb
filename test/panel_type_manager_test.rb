require_relative '../lib/ui/panel_type_manager'

# Мок объект панели для тестирования
class MockPane
  attr_reader :terminal_mode, :file_tree_mode, :current_file, :is_new_file
  
  def initialize(type, has_file: false, is_new: false)
    @type = type
    @current_file = has_file ? "test.rb" : nil
    @is_new_file = is_new
  end
  
  def terminal_mode?
    @type == :terminal
  end
  
  def file_tree_mode?
    @type == :file_tree
  end
  
  def current_file
    @current_file
  end
  
  def is_new_file
    @is_new_file
  end
end

# Тесты эвристики
class PanelTypeManagerTest
  def initialize
    @passed = 0
    @failed = 0
  end
  
  def assert(condition, message)
    if condition
      @passed += 1
      puts "✓ #{message}"
    else
      @failed += 1
      puts "✗ #{message}"
    end
  end
  
  def run_tests
    puts "=== Тестирование PanelTypeManager ==="
    
    test_panel_type_detection
    test_find_panels_by_type
    test_find_best_editor_panel
    test_find_best_focus_panel
    test_should_create_new_panel
    test_panel_stats
    
    puts "\n=== Результаты ==="
    puts "Пройдено: #{@passed}"
    puts "Провалено: #{@failed}"
    puts "Общий результат: #{@failed == 0 ? 'УСПЕХ' : 'ПРОВАЛ'}"
  end
  
  private
  
  def test_panel_type_detection
    puts "\n--- Тест определения типов панелей ---"
    
    editor_pane = MockPane.new(:editor)
    tree_pane = MockPane.new(:file_tree)
    terminal_pane = MockPane.new(:terminal)
    
    manager = PanelTypeManager.new([editor_pane, tree_pane, terminal_pane])
    
    assert(manager.get_panel_type(editor_pane) == :editor, "Определение типа редактора")
    assert(manager.get_panel_type(tree_pane) == :file_tree, "Определение типа файлового дерева")
    assert(manager.get_panel_type(terminal_pane) == :terminal, "Определение типа терминала")
  end
  
  def test_find_panels_by_type
    puts "\n--- Тест поиска панелей по типу ---"
    
    panes = [
      MockPane.new(:editor),
      MockPane.new(:file_tree),
      MockPane.new(:editor),
      MockPane.new(:terminal)
    ]
    
    manager = PanelTypeManager.new(panes)
    
    assert(manager.find_panels_by_type(:editor).count == 2, "Найдено 2 редактора")
    assert(manager.find_panels_by_type(:file_tree).count == 1, "Найдено 1 файловое дерево")
    assert(manager.find_panels_by_type(:terminal).count == 1, "Найден 1 терминал")
  end
  
  def test_find_best_editor_panel
    puts "\n--- Тест поиска лучшего редактора ---"
    
    # Сценарий 1: нет редакторов
    manager = PanelTypeManager.new([MockPane.new(:terminal)])
    assert(manager.find_best_editor_panel.nil?, "Нет редакторов - возвращает nil")
    
    # Сценарий 2: есть редактор с файлом
    editor_with_file = MockPane.new(:editor, has_file: true)
    editor_empty = MockPane.new(:editor, is_new: true)
    
    manager = PanelTypeManager.new([editor_empty, editor_with_file])
    assert(manager.find_best_editor_panel == editor_with_file, "Предпочтение редактору с файлом")
    
    # Сценарий 3: только пустой редактор
    manager = PanelTypeManager.new([editor_empty])
    assert(manager.find_best_editor_panel == editor_empty, "Выбор пустого редактора")
  end
  
  def test_find_best_focus_panel
    puts "\n--- Тест поиска лучшего фокуса ---"
    
    editor = MockPane.new(:editor)
    tree = MockPane.new(:file_tree)
    terminal = MockPane.new(:terminal)
    
    # Сценарий 1: все типы панелей
    manager = PanelTypeManager.new([terminal, tree, editor])
    assert(manager.find_best_focus_panel == editor, "Предпочтение редактору")
    
    # Сценарий 2: исключаем редакторы
    assert(manager.find_best_focus_panel([:editor]) == tree, "Файловое дерево после исключения редакторов")
    
    # Сценарий 3: только терминал
    manager = PanelTypeManager.new([terminal])
    assert(manager.find_best_focus_panel == terminal, "Терминал если нет других")
  end
  
  def test_should_create_new_panel
    puts "\n--- Тест необходимости создания новой панели ---"
    
    # Сценарий 1: нет редакторов
    manager = PanelTypeManager.new([MockPane.new(:terminal)])
    assert(manager.should_create_new_panel_for_file?, "Создать панель если нет редакторов")
    
    # Сценарий 2: есть редактор
    manager = PanelTypeManager.new([MockPane.new(:editor)])
    assert(!manager.should_create_new_panel_for_file?, "Не создавать если есть редактор")
  end
  
  def test_panel_stats
    puts "\n--- Тест статистики панелей ---"
    
    panes = [
      MockPane.new(:editor),
      MockPane.new(:editor),
      MockPane.new(:file_tree),
      MockPane.new(:terminal)
    ]
    
    manager = PanelTypeManager.new(panes)
    stats = manager.get_panel_stats
    
    assert(stats[:total] == 4, "Общее количество панелей")
    assert(stats[:editors] == 2, "Количество редакторов")
    assert(stats[:file_trees] == 1, "Количество файловых деревьев")
    assert(stats[:terminals] == 1, "Количество терминалов")
  end
end

# Запуск тестов
if __FILE__ == $0
  test = PanelTypeManagerTest.new
  test.run_tests
end 