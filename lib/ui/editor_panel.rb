require_relative 'base_panel'
require_relative 'code_editor'

class EditorPanel < BasePanel
  def initialize
    super(:editor)
    @current_editor = CodeEditor.new
    @current_file = nil
    @is_new_file = true
    @original_temp_file = nil
    @file_history = []
    @max_history_size = 20
    
    setup_editor
  end

  def setup_ui
    # Создаем заголовок с кнопками
    create_header
    
    # Добавляем редактор
    @box.pack_start(@current_editor.widget, expand: true, fill: true, padding: 0)
    
    # Обработчики событий
    @current_editor.on_modified { emit_modified }
    @current_editor.on_save_request { @on_save_callback.call(self) if @on_save_callback }
    @current_editor.on_focus { set_focus }
  end

  def get_title
    return "Untitled" if @is_new_file
    return "New File" if @current_file.nil?
    
    basename = File.basename(@current_file)
    modified = has_unsaved_changes? ? " *" : ""
    "#{basename}#{modified}"
  end

  def has_unsaved_changes?
    @current_editor.is_modified?
  end

  def save
    if @is_new_file
      @on_save_callback.call(self) if @on_save_callback
    else
      @current_editor.save_file
      emit_modified
    end
  end

  def focus
    @current_editor.focus
  end

  def can_close?
    return true unless has_unsaved_changes?
    
    dialog = Gtk::MessageDialog.new(
      parent: nil,
      flags: :destroy_with_parent,
      type: :question,
      buttons_type: :yes_no,
      message: "File has unsaved changes. Close anyway?"
    )
    
    response = dialog.run
    dialog.destroy
    response == :yes
  end

  def load_file(file_path)
    @current_file = file_path
    @is_new_file = false
    @current_editor.load_file(file_path)
    
    # Добавляем в историю
    add_to_history(file_path)
    
    update_title
    emit_modified
  end

  def get_content
    @current_editor.get_content
  end

  def set_content(content)
    @current_editor.set_content(content)
  end

  def get_current_editor
    @current_editor
  end

  def mark_as_saved(file_path)
    @current_file = file_path
    @is_new_file = false
    @current_editor.mark_as_saved
    update_title
    
    # Добавляем в историю
    add_to_history(file_path)
    
    @on_file_saved_callback.call(file_path) if @on_file_saved_callback
  end

  def get_file_history
    @file_history
  end

  def is_new_file?
    @is_new_file
  end

  def has_file?
    !@current_file.nil?
  end

  private

  def setup_editor
    # Создаем временный файл для нового документа
    temp_file = "/tmp/untitled_#{Time.now.to_i}.txt"
    File.write(temp_file, "")
    @current_editor.load_file(temp_file)
    @original_temp_file = temp_file
    update_title
  end

  def create_header
    header_box = Gtk::Box.new(:horizontal, 0)
    
    # Заголовок
    @title_label = Gtk::Label.new(get_title)
    @title_label.set_xalign(0.0)
    @title_label.override_color(:normal, Gdk::RGBA::new(0.9, 0.9, 0.9, 1.0))
    
    # Кнопки
    buttons_box = create_button_bar
    
    # Кнопки для редактора
    buttons_box.pack_start(create_button("⊞", :focus, "Focus"), expand: false, fill: false, padding: 1)
    buttons_box.pack_start(create_button("❙", :split_vertical, "Split Vertical"), expand: false, fill: false, padding: 1)
    buttons_box.pack_start(create_button("═", :split_horizontal, "Split Horizontal"), expand: false, fill: false, padding: 1)
    buttons_box.pack_start(create_button("⏷", :history, "File History"), expand: false, fill: false, padding: 1)
    buttons_box.pack_start(create_button("💾", :save, "Save"), expand: false, fill: false, padding: 1)
    buttons_box.pack_start(create_button("✗", :close, "Close"), expand: false, fill: false, padding: 1)
    
    header_box.pack_start(@title_label, expand: true, fill: true, padding: 5)
    header_box.pack_start(buttons_box, expand: false, fill: false, padding: 2)
    
    @box.pack_start(header_box, expand: false, fill: false, padding: 0)
  end

  def update_title
    @title_label.text = get_title if @title_label
  end

  def add_to_history(file_path)
    return if file_path.nil? || file_path.start_with?("/tmp/")
    
    # Удаляем если уже есть
    @file_history.delete(file_path)
    
    # Добавляем в начало
    @file_history.unshift(file_path)
    
    # Ограничиваем размер
    @file_history = @file_history.first(@max_history_size)
  end

  def handle_button_click(action)
    case action
    when :save
      save
    else
      super(action)
    end
  end
end 