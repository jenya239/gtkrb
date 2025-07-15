require 'gtk3'
require_relative 'editor_pane'
require_relative 'split_container'

class EditorManager
  def initialize
    @panes = []
    @active_pane = nil
    @container = SplitContainer.new
    @on_modified_callbacks = []
    @on_file_saved_callback = nil
    setup_initial_pane
  end

  def widget
    @container.widget
  end

  def load_file(file_path)
    # Открываем файл в активном редакторе
    if @active_pane
      @active_pane.load_file(file_path)
    else
      create_pane.load_file(file_path)
    end
  end

  def split_horizontal
    new_pane = create_pane
    @container.split_horizontal(@active_pane, new_pane)
    @active_pane = new_pane
  end

  def split_vertical
    new_pane = create_pane
    @container.split_vertical(@active_pane, new_pane)
    @active_pane = new_pane
  end

  def close_active_pane
    close_pane(@active_pane) if @active_pane
  end

  def on_modified(&block)
    @on_modified_callbacks << block
  end

  def on_file_saved(&block)
    @on_file_saved_callback = block
  end

  def get_active_pane
    @active_pane
  end

  def get_all_panes
    @panes.dup
  end

  def get_active_file
    @active_pane ? @active_pane.get_current_file : nil
  end

  private

  def setup_initial_pane
    @active_pane = create_pane
    @container.set_root(@active_pane)
  end

  def create_pane
    pane = EditorPane.new
    @panes << pane
    
    pane.on_focus do |p| 
      # Обновляем активную панель
      old_active = @active_pane
      @active_pane = p
      
      # Обновляем стили
      @panes.each { |pane| pane.set_inactive_style }
      p.set_active_style
    end
    
    pane.on_modified { emit_modified }
    pane.on_button { |clicked_pane| swap_with_active(clicked_pane) }
    pane.on_close { |p| close_pane(p) }
    pane.on_split_horizontal { |p| split_pane_horizontal(p) }
    pane.on_split_vertical { |p| split_pane_vertical(p) }
    pane.on_new_file { |p| create_new_file(p) }
    pane.on_save { |p| show_save_dialog(p) }
    pane.on_file_saved { |file_path| @on_file_saved_callback.call(file_path) if @on_file_saved_callback }
    
    pane
  end

  def split_pane_horizontal(pane)
    @active_pane = pane
    split_horizontal
  end

  def split_pane_vertical(pane)
    @active_pane = pane
    split_vertical
  end

  def create_new_file(pane)
    @active_pane = pane
    # Создаем временный файл
    temp_file = "/tmp/untitled_#{Time.now.to_i}.txt"
    File.write(temp_file, "")
    pane.load_file(temp_file)
    
    # Помечаем как новый файл для сохранения
    pane.instance_variable_set(:@is_new_file, true)
    pane.instance_variable_set(:@original_temp_file, temp_file)
    
    # Добавляем callback для сохранения
    pane.get_current_editor.on_save_request { show_save_dialog(pane) }
  end

  def show_save_dialog(pane)
    dialog = Gtk::FileChooserDialog.new(
      title: "Save File As",
      parent: nil,
      action: :save,
      buttons: [
        [Gtk::Stock::CANCEL, :cancel],
        [Gtk::Stock::SAVE, :accept]
      ]
    )
    
    dialog.set_current_name("untitled.txt")
    
    if dialog.run == :accept
      filename = dialog.filename
      current_content = pane.get_current_editor.get_content
      
      begin
        File.write(filename, current_content)
        pane.mark_as_saved(filename)
        emit_modified
      rescue => e
        puts "Error saving file: #{e.message}"
      end
    end
    
    dialog.destroy
  end

  def swap_with_active(clicked_pane)
    puts "=== SWAP DEBUG ==="
    puts "Active pane: #{@active_pane.pane_id}"
    puts "Clicked pane: #{clicked_pane.pane_id}"
    puts "Active has_file: #{@active_pane.has_file?}"
    puts "Clicked has_file: #{clicked_pane.has_file?}"
    puts "Active is_new: #{@active_pane.is_new_file?}"
    puts "Clicked is_new: #{clicked_pane.is_new_file?}"
    puts "Active content length: #{@active_pane.get_current_editor.get_content.strip.length}"
    puts "Clicked content length: #{clicked_pane.get_current_editor.get_content.strip.length}"
    
    return unless @active_pane
    return if @active_pane == clicked_pane
    return unless @active_pane.has_file? && clicked_pane.has_file?
    
    puts "Starting swap..."
    
    # Обмениваем редакторы между панелями
    @active_pane.swap_editors_with(clicked_pane)
    
    # Устанавливаем фокус на панель куда кликнули
    @active_pane = clicked_pane
    clicked_pane.set_focus
    
    puts "Swap completed!"
    puts "=================="
    
    emit_modified
  end

  def close_pane(pane)
    # Не закрываем последнюю панель только если она единственная
    return if @panes.length <= 1
    
    @panes.delete(pane)
    @container.remove_pane(pane)
    @active_pane = @panes.first if @active_pane == pane
  end

  def emit_modified
    @on_modified_callbacks.each(&:call)
  end
end 