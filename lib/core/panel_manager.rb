require_relative 'editor_model'

class PanelManager
  attr_reader :panels, :active_panel_id, :split_tree
  
  def initialize
    @panels = {}
    @active_panel_id = nil
    @split_tree = nil
    @observers = []
  end
  
  def create_panel(editor_model = nil)
    panel_id = "panel_#{rand(1000000)}"
    editor_model ||= EditorModel.new
    
    @panels[panel_id] = {
      id: panel_id,
      editor: editor_model,
      created_at: Time.now
    }
    
    # Устанавливаем как активную панель
    if @active_panel_id.nil?
      @active_panel_id = panel_id
      @split_tree = panel_id if @split_tree.nil?
    end
    
    notify_observers(:panel_created, panel_id)
    panel_id
  end
  
  def remove_panel(panel_id)
    return false unless @panels[panel_id]
    
    @panels.delete(panel_id)
    
    # Выбираем новую активную панель
    if @active_panel_id == panel_id
      @active_panel_id = @panels.keys.first
    end
    
    # Обновляем split_tree, удаляя панель
    @split_tree = remove_from_split_tree(@split_tree, panel_id) if @split_tree
    
    notify_observers(:panel_removed, panel_id)
    true
  end
  
  def set_active_panel(panel_id)
    return false unless @panels[panel_id]
    
    old_active = @active_panel_id
    @active_panel_id = panel_id
    notify_observers(:active_panel_changed, old_active, panel_id)
    true
  end
  
  def get_panel(panel_id)
    @panels[panel_id]
  end
  
  def get_active_panel
    @panels[@active_panel_id]
  end
  
  def get_editor(panel_id)
    panel = @panels[panel_id]
    panel ? panel[:editor] : nil
  end
  
  def get_active_editor
    panel = get_active_panel
    panel ? panel[:editor] : nil
  end
  
  def load_multiple_files(file_paths)
    return if file_paths.empty?
    
    # Очищаем существующие панели
    @panels.clear
    @active_panel_id = nil
    @split_tree = nil
    
    # Создаем первую панель
    first_editor = EditorModel.new
    first_editor.load_file(file_paths.first)
    first_panel_id = create_panel(first_editor)
    
    # Если только один файл, устанавливаем простое дерево
    if file_paths.size == 1
      @split_tree = first_panel_id
      notify_observers(:layout_changed, @split_tree)
      return
    end
    
    # Создаем остальные панели через split'ы
    remaining_files = file_paths[1..-1]
    @split_tree = create_optimal_splits(first_panel_id, remaining_files)
    
    notify_observers(:layout_changed, @split_tree)
  end
  
  def split_horizontal(existing_panel_id = nil)
    existing_panel_id ||= @active_panel_id
    return unless existing_panel_id
    
    new_panel_id = create_panel
    
    # Обновляем split_tree
    @split_tree = insert_split_in_tree(@split_tree, existing_panel_id, :horizontal, new_panel_id)
    
    @active_panel_id = new_panel_id
    notify_observers(:layout_changed, @split_tree)
    new_panel_id
  end
  
  def split_vertical(existing_panel_id = nil)
    existing_panel_id ||= @active_panel_id
    return unless existing_panel_id
    
    new_panel_id = create_panel
    
    # Обновляем split_tree
    @split_tree = insert_split_in_tree(@split_tree, existing_panel_id, :vertical, new_panel_id)
    
    @active_panel_id = new_panel_id
    notify_observers(:layout_changed, @split_tree)
    new_panel_id
  end
  
  def swap_panels(panel1_id, panel2_id)
    return false unless @panels[panel1_id] && @panels[panel2_id]
    
    # Меняем местами редакторы
    editor1 = @panels[panel1_id][:editor]
    editor2 = @panels[panel2_id][:editor]
    
    @panels[panel1_id][:editor] = editor2
    @panels[panel2_id][:editor] = editor1
    
    notify_observers(:panels_swapped, panel1_id, panel2_id)
    true
  end
  
  def add_observer(&block)
    @observers << block
  end
  
  def panel_count
    @panels.size
  end
  
  def single_panel?
    @panels.size == 1
  end
  
  private
  
  def create_optimal_splits(root_panel_id, file_paths)
    return root_panel_id if file_paths.empty?
    
    total_files = file_paths.size + 1 # +1 для root панели
    cols = Math.sqrt(total_files).ceil
    rows = (total_files.to_f / cols).ceil
    
    current_tree = root_panel_id
    current_panel_id = root_panel_id
    
    file_paths.each_with_index do |file_path, index|
      # Создаем редактор для файла
      editor = EditorModel.new
      editor.load_file(file_path)
      new_panel_id = create_panel(editor)
      
      # Определяем направление split'а для оптимальной сетки
      row = (index + 1) / cols
      col = (index + 1) % cols
      
      # Чередуем горизонтальные и вертикальные split'ы для создания сетки
      if col == 0
        # Новая строка - вертикальный split
        current_tree = insert_split_in_tree(current_tree, current_panel_id, :vertical, new_panel_id)
      else
        # Та же строка - горизонтальный split
        current_tree = insert_split_in_tree(current_tree, current_panel_id, :horizontal, new_panel_id)
      end
      
      current_panel_id = new_panel_id
    end
    
    current_tree
  end
  
  def insert_split_in_tree(tree, target_panel_id, direction, new_panel_id)
    # Если дерево это просто панель
    if tree.is_a?(String)
      return tree == target_panel_id ? create_split_node(direction, tree, new_panel_id) : tree
    end
    
    # Если дерево это split узел
    if tree.is_a?(Hash)
      if tree[:left] == target_panel_id
        tree[:left] = create_split_node(direction, target_panel_id, new_panel_id)
      elsif tree[:right] == target_panel_id
        tree[:right] = create_split_node(direction, target_panel_id, new_panel_id)
      elsif tree[:top] == target_panel_id
        tree[:top] = create_split_node(direction, target_panel_id, new_panel_id)
      elsif tree[:bottom] == target_panel_id
        tree[:bottom] = create_split_node(direction, target_panel_id, new_panel_id)
      else
        # Рекурсивно ищем в поддеревьях
        tree[:left] = insert_split_in_tree(tree[:left], target_panel_id, direction, new_panel_id) if tree[:left]
        tree[:right] = insert_split_in_tree(tree[:right], target_panel_id, direction, new_panel_id) if tree[:right]
        tree[:top] = insert_split_in_tree(tree[:top], target_panel_id, direction, new_panel_id) if tree[:top]
        tree[:bottom] = insert_split_in_tree(tree[:bottom], target_panel_id, direction, new_panel_id) if tree[:bottom]
      end
    end
    
    tree
  end
  
  def create_split_node(direction, panel1_id, panel2_id)
    if direction == :horizontal
      { type: :horizontal, left: panel1_id, right: panel2_id }
    else
      { type: :vertical, top: panel1_id, bottom: panel2_id }
    end
  end
  
  def remove_from_split_tree(tree, panel_id)
    return nil if tree == panel_id
    
    if tree.is_a?(Hash)
      # Проверяем, не является ли один из дочерних элементов удаляемой панелью
      if tree[:left] == panel_id
        return tree[:right]
      elsif tree[:right] == panel_id
        return tree[:left]
      elsif tree[:top] == panel_id
        return tree[:bottom]
      elsif tree[:bottom] == panel_id
        return tree[:top]
      else
        # Рекурсивно удаляем из поддеревьев
        tree[:left] = remove_from_split_tree(tree[:left], panel_id) if tree[:left]
        tree[:right] = remove_from_split_tree(tree[:right], panel_id) if tree[:right]
        tree[:top] = remove_from_split_tree(tree[:top], panel_id) if tree[:top]
        tree[:bottom] = remove_from_split_tree(tree[:bottom], panel_id) if tree[:bottom]
      end
    end
    
    tree
  end
  
  def notify_observers(event, *args)
    @observers.each { |obs| obs.call(event, *args) }
  end
end 