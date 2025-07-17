require_relative '../../lib/core/panel_manager'
require_relative '../../lib/core/editor_model'

class PanelManagerTest
  def self.run_all
    puts "=== Panel Manager Tests ==="
    
    test_single_panel
    test_horizontal_split
    test_vertical_split
    test_multiple_files_2
    test_multiple_files_4
    test_multiple_files_6
    test_panel_removal
    test_panel_swapping
    
    puts "All tests passed!"
  end
  
  def self.test_single_panel
    puts "Testing single panel..."
    
    manager = PanelManager.new
    assert_equal(0, manager.panel_count)
    
    panel_id = manager.create_panel
    assert_equal(1, manager.panel_count)
    assert_equal(panel_id, manager.active_panel_id)
    assert_equal(panel_id, manager.split_tree)
    
    puts "✓ Single panel test passed"
  end
  
  def self.test_horizontal_split
    puts "Testing horizontal split..."
    
    manager = PanelManager.new
    panel1_id = manager.create_panel
    panel2_id = manager.split_horizontal
    
    assert_equal(2, manager.panel_count)
    assert_equal(panel2_id, manager.active_panel_id)
    
    tree = manager.split_tree
    assert_equal(:horizontal, tree[:type])
    assert_equal(panel1_id, tree[:left])
    assert_equal(panel2_id, tree[:right])
    
    puts "✓ Horizontal split test passed"
  end
  
  def self.test_vertical_split
    puts "Testing vertical split..."
    
    manager = PanelManager.new
    panel1_id = manager.create_panel
    panel2_id = manager.split_vertical
    
    assert_equal(2, manager.panel_count)
    assert_equal(panel2_id, manager.active_panel_id)
    
    tree = manager.split_tree
    assert_equal(:vertical, tree[:type])
    assert_equal(panel1_id, tree[:top])
    assert_equal(panel2_id, tree[:bottom])
    
    puts "✓ Vertical split test passed"
  end
  
  def self.test_multiple_files_2
    puts "Testing 2 files load..."
    
    manager = PanelManager.new
    manager.load_multiple_files(['file1.rb', 'file2.rb'])
    
    assert_equal(2, manager.panel_count)
    
    tree = manager.split_tree
    assert_equal(:horizontal, tree[:type])
    assert(tree[:left].is_a?(String))
    assert(tree[:right].is_a?(String))
    
    # Проверяем что файлы загрузились
    editor1 = manager.get_editor(tree[:left])
    editor2 = manager.get_editor(tree[:right])
    assert_equal('file1.rb', editor1.file_path)
    assert_equal('file2.rb', editor2.file_path)
    
    puts "✓ 2 files load test passed"
  end
  
  def self.test_multiple_files_4
    puts "Testing 4 files load..."
    
    manager = PanelManager.new
    manager.load_multiple_files(['file1.rb', 'file2.rb', 'file3.rb', 'file4.rb'])
    
    assert_equal(4, manager.panel_count)
    
    # Проверяем что создалась правильная структура split'ов
    tree = manager.split_tree
    assert(tree.is_a?(Hash))
    
    # Проверяем что все файлы загрузились
    panel_ids = collect_panel_ids(tree)
    assert_equal(4, panel_ids.size)
    
    panel_ids.each_with_index do |panel_id, index|
      editor = manager.get_editor(panel_id)
      assert_equal("file#{index + 1}.rb", editor.file_path)
    end
    
    puts "✓ 4 files load test passed"
  end
  
  def self.test_multiple_files_6
    puts "Testing 6 files load..."
    
    manager = PanelManager.new
    files = ['file1.rb', 'file2.rb', 'file3.rb', 'file4.rb', 'file5.rb', 'file6.rb']
    manager.load_multiple_files(files)
    
    assert_equal(6, manager.panel_count)
    
    # Проверяем что все файлы загрузились
    panel_ids = collect_panel_ids(manager.split_tree)
    assert_equal(6, panel_ids.size)
    
    puts "✓ 6 files load test passed"
  end
  
  def self.test_panel_removal
    puts "Testing panel removal..."
    
    manager = PanelManager.new
    panel1_id = manager.create_panel
    panel2_id = manager.split_horizontal
    
    assert_equal(2, manager.panel_count)
    
    # Удаляем панель
    manager.remove_panel(panel1_id)
    assert_equal(1, manager.panel_count)
    assert_equal(panel2_id, manager.split_tree)
    
    puts "✓ Panel removal test passed"
  end
  
  def self.test_panel_swapping
    puts "Testing panel swapping..."
    
    manager = PanelManager.new
    manager.load_multiple_files(['file1.rb', 'file2.rb'])
    
    tree = manager.split_tree
    panel1_id = tree[:left]
    panel2_id = tree[:right]
    
    # Проверяем исходное состояние
    assert_equal('file1.rb', manager.get_editor(panel1_id).file_path)
    assert_equal('file2.rb', manager.get_editor(panel2_id).file_path)
    
    # Меняем местами
    manager.swap_panels(panel1_id, panel2_id)
    
    # Проверяем что файлы поменялись местами
    assert_equal('file2.rb', manager.get_editor(panel1_id).file_path)
    assert_equal('file1.rb', manager.get_editor(panel2_id).file_path)
    
    puts "✓ Panel swapping test passed"
  end
  
  private
  
  def self.collect_panel_ids(tree)
    return [tree] if tree.is_a?(String)
    
    panel_ids = []
    if tree.is_a?(Hash)
      panel_ids += collect_panel_ids(tree[:left]) if tree[:left]
      panel_ids += collect_panel_ids(tree[:right]) if tree[:right]
      panel_ids += collect_panel_ids(tree[:top]) if tree[:top]
      panel_ids += collect_panel_ids(tree[:bottom]) if tree[:bottom]
    end
    
    panel_ids
  end
  
  def self.assert_equal(expected, actual)
    raise "Expected #{expected}, got #{actual}" unless expected == actual
  end
  
  def self.assert(condition)
    raise "Assertion failed" unless condition
  end
end

# Запускаем тесты
PanelManagerTest.run_all 