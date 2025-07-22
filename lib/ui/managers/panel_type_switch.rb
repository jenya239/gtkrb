class PanelTypeSwitch
  def self.convert_to_file_manager(panel_manager, panel, root_dir = nil)
    root_dir ||= get_directory_from_panel(panel)
    
    # Создаем новую панель файлового менеджера
    new_panel = PanelFactory.create_panel(:file_manager, root_dir: root_dir)
    
    # Заменяем панель в менеджере
    panel_manager.replace_panel(panel, new_panel)
    
    # Регистрируем в координаторе
    coordinator = panel_manager.instance_variable_get(:@file_tree_coordinator)
    coordinator.register_file_tree(new_panel.panel_id, root_dir)
    
    new_panel
  end
  
  def self.convert_to_editor(panel_manager, panel, file_path = nil)
    # Создаем новую панель редактора
    new_panel = PanelFactory.create_panel(:editor)
    
    # Загружаем файл если указан
    new_panel.load_file(file_path) if file_path
    
    # Заменяем панель в менеджере
    panel_manager.replace_panel(panel, new_panel)
    
    # Отменяем регистрацию в координаторе если это было файловое дерево
    if panel.panel_type == :file_manager
      coordinator = panel_manager.instance_variable_get(:@file_tree_coordinator)
      coordinator.unregister_file_tree(panel.panel_id)
    end
    
    new_panel
  end
  
  def self.convert_to_terminal(panel_manager, panel, working_dir = nil)
    working_dir ||= get_directory_from_panel(panel)
    
    # Создаем новую панель терминала
    new_panel = PanelFactory.create_panel(:terminal, working_dir: working_dir)
    
    # Заменяем панель в менеджере
    panel_manager.replace_panel(panel, new_panel)
    
    # Отменяем регистрацию в координаторе если это было файловое дерево
    if panel.panel_type == :file_manager
      coordinator = panel_manager.instance_variable_get(:@file_tree_coordinator)
      coordinator.unregister_file_tree(panel.panel_id)
    end
    
    new_panel
  end
  
  private
  
  def self.get_directory_from_panel(panel)
    case panel.panel_type
    when :file_manager
      panel.get_current_dir
    when :editor
      # Получаем директорию из текущего файла
      current_file = panel.respond_to?(:get_current_file) ? panel.get_current_file : nil
      if current_file && !current_file.empty?
        File.dirname(current_file)
      else
        Dir.pwd
      end
    when :terminal
      # Получаем рабочую директорию терминала
      if panel.respond_to?(:get_working_dir)
        panel.get_working_dir
      else
        Dir.pwd
      end
    else
      Dir.pwd
    end
  end
end 