require_relative '../core/panel_manager'
require_relative 'gtk_split_adapter'

class NewEditorManager
  def initialize
    @panel_manager = PanelManager.new
    @gtk_adapter = GtkSplitAdapter.new(@panel_manager)
    @on_modified_callbacks = []
    @on_file_saved_callback = nil
    
    # Подписываемся на события для обратной связи
    @panel_manager.add_observer do |event, *args|
      handle_panel_manager_event(event, *args)
    end
  end
  
  def widget
    @gtk_adapter.widget
  end
  
  def load_file(file_path)
    editor = @panel_manager.get_active_editor
    if editor
      editor.load_file(file_path)
    end
  end
  
  def load_multiple_files(file_paths)
    @panel_manager.load_multiple_files(file_paths)
  end
  
  def load_directory(directory_path)
    return unless Dir.exist?(directory_path)
    
    files = Dir.glob(File.join(directory_path, "**/*")).select { |f| File.file?(f) }
    load_multiple_files(files)
  end
  
  def load_directories(directory_paths)
    all_files = []
    directory_paths.each do |dir|
      next unless Dir.exist?(dir)
      files = Dir.glob(File.join(dir, "**/*")).select { |f| File.file?(f) }
      all_files.concat(files)
    end
    load_multiple_files(all_files)
  end
  
  def split_horizontal
    @panel_manager.split_horizontal
  end
  
  def split_vertical
    @panel_manager.split_vertical
  end
  
  def close_active_pane
    if @panel_manager.active_panel_id
      @panel_manager.remove_panel(@panel_manager.active_panel_id)
    end
  end
  
  def new_file
    editor = @panel_manager.get_active_editor
    if editor
      editor.new_file
    end
  end
  
  def save_file
    editor = @panel_manager.get_active_editor
    if editor
      if editor.has_file?
        editor.save
      else
        # Показываем диалог Save As
        save_as_dialog
      end
    end
  end
  
  def save_as_dialog
    dialog = Gtk::FileChooserDialog.new(
      title: "Save As",
      parent: nil,
      action: Gtk::FileChooserAction::SAVE,
      buttons: [
        [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL],
        [Gtk::Stock::SAVE, Gtk::ResponseType::ACCEPT]
      ]
    )
    
    response = dialog.run
    if response == Gtk::ResponseType::ACCEPT
      file_path = dialog.filename
      editor = @panel_manager.get_active_editor
      if editor
        editor.save_as(file_path)
      end
    end
    
    dialog.destroy
  end
  
  def get_active_pane
    panel = @panel_manager.get_active_panel
    return nil unless panel
    
    # Создаем адаптер для обратной совместимости
    ActivePaneAdapter.new(panel[:editor])
  end
  
  def on_modified(&block)
    @on_modified_callbacks << block
  end
  
  def on_file_saved(&block)
    @on_file_saved_callback = block
  end
  
  def swap_panels(panel1_id, panel2_id)
    @panel_manager.swap_panels(panel1_id, panel2_id)
  end
  
  private
  
  def handle_panel_manager_event(event, *args)
    case event
    when :panel_created
      # Новая панель создана
    when :panel_removed
      # Панель удалена
    when :active_panel_changed
      # Активная панель изменилась
    when :panels_swapped
      # Панели поменялись местами
    when :layout_changed
      # Обновился layout
    end
  end
  
  def emit_modified
    @on_modified_callbacks.each { |callback| callback.call }
  end
  
  def emit_file_saved(file_path)
    @on_file_saved_callback.call(file_path) if @on_file_saved_callback
  end
end

# Адаптер для обратной совместимости
class ActivePaneAdapter
  def initialize(editor_model)
    @editor_model = editor_model
  end
  
  def get_current_editor
    EditorAdapter.new(@editor_model)
  end
  
  def set_focus
    # GTK focus будет управляться через adapter
  end
end

# Адаптер для editor модели
class EditorAdapter
  def initialize(editor_model)
    @editor_model = editor_model
  end
  
  def file_path
    @editor_model.file_path
  end
  
  def modified?
    @editor_model.modified?
  end
end 