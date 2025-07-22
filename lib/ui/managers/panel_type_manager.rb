class PanelTypeManager
  PANEL_TYPES = {
    editor: :editor,
    file_tree: :file_tree,
    terminal: :terminal
  }.freeze

  def initialize(panes)
    @panes = panes
    @active_representatives = {
      editor: nil,
      file_tree: nil,
      terminal: nil
    }
  end

  def get_panel_type(pane)
    return :terminal if pane.terminal_mode?
    return :file_tree if pane.file_tree_mode?
    :editor
  end

  def find_panels_by_type(type)
    @panes.select { |pane| get_panel_type(pane) == type }
  end

  def find_best_editor_panel
    editors = find_panels_by_type(:editor)
    return nil if editors.empty?
    
    # Сначала проверяем активного представителя редактора
    active_editor = get_active_representative(:editor)
    if active_editor && get_panel_type(active_editor) == :editor
      return active_editor
    end
    
    # Эвристика: предпочитаем панель с уже открытым файлом, затем пустую
    editor_with_file = editors.find { |pane| pane.current_file }
    editor_empty = editors.find { |pane| pane.is_new_file }
    
    editor_with_file || editor_empty || editors.first
  end

  def find_best_focus_panel(exclude_types = [])
    # Порядок предпочтения фокуса: редактор -> файловое дерево -> терминал
    preferred_order = [:editor, :file_tree, :terminal] - exclude_types
    
    preferred_order.each do |type|
      panels = find_panels_by_type(type)
      return panels.first unless panels.empty?
    end
    
    nil
  end

  def should_create_new_panel_for_file?
    # Создаем новую панель если нет подходящих редакторов
    find_best_editor_panel.nil?
  end

  def find_widest_panel
    # Находим самую широкую панель для разделения
    # Пока просто возвращаем первую панель
    @panes.first
  end

  def set_active_representative(type, pane)
    @active_representatives[type] = pane
  end

  def get_active_representative(type)
    @active_representatives[type]
  end

  def clear_active_representative(type)
    @active_representatives[type] = nil
  end

  def get_panel_stats
    {
      total: @panes.count,
      editors: find_panels_by_type(:editor).count,
      file_trees: find_panels_by_type(:file_tree).count,
      terminals: find_panels_by_type(:terminal).count
    }
  end

  def suggest_panel_conversion(from_type, to_type)
    # Эвристика для разумного преобразования панелей
    case [from_type, to_type]
    when [:editor, :file_tree]
      "Редактор → Файловое дерево: панель станет навигатором"
    when [:file_tree, :editor]
      "Файловое дерево → Редактор: панель станет редактором"
    when [:terminal, :editor]
      "Терминал → Редактор: панель станет редактором"
    else
      "Преобразование #{from_type} → #{to_type}"
    end
  end
end 