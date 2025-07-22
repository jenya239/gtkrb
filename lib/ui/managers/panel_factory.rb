require_relative '../panels/editor_panel'
require_relative '../panels/terminal_panel'
require_relative '../panels/file_manager_panel'

class PanelFactory
  # Создает панель указанного типа
  def self.create_panel(type, options = {})
    case type
    when :editor
      EditorPanel.new
    when :terminal
      working_dir = options[:working_dir] || Dir.pwd
      TerminalPanel.new(working_dir)
    when :file_manager
      root_dir = options[:root_dir] || Dir.pwd
      FileManagerPanel.new(root_dir)
    else
      raise ArgumentError, "Unknown panel type: #{type}"
    end
  end

  # Возвращает список поддерживаемых типов панелей
  def self.supported_types
    [:editor, :terminal, :file_manager]
  end

  # Создает панель редактора с загруженным файлом
  def self.create_editor_with_file(file_path)
    panel = create_panel(:editor)
    panel.load_file(file_path)
    panel
  end

  # Создает панель терминала в указанной директории
  def self.create_terminal_in_dir(dir)
    create_panel(:terminal, working_dir: dir)
  end

  # Создает панель файлового менеджера для указанной директории
  def self.create_file_manager_for_dir(dir)
    create_panel(:file_manager, root_dir: dir)
  end

  # Определяет тип панели по её объекту
  def self.get_panel_type(panel)
    case panel
    when EditorPanel
      :editor
    when TerminalPanel
      :terminal
    when FileManagerPanel
      :file_manager
    else
      :unknown
    end
  end

  # Создает панель подходящего типа для файла
  def self.create_panel_for_file(file_path)
    if File.directory?(file_path)
      create_file_manager_for_dir(file_path)
    else
      create_editor_with_file(file_path)
    end
  end
end 