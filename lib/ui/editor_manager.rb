require 'gtk3'
require_relative 'editor_pane'
require_relative 'split_container'

class EditorManager
  def initialize(container)
    @container = container
    @panes = []
    @active_pane = nil
    @grid_mode = false
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
    if @grid_mode
      exit_grid_mode
    end
    
    if @active_pane
      new_pane = create_pane
      @container.split_horizontal(@active_pane, new_pane)
      @active_pane = new_pane
      @active_pane.set_focus
    end
  end

  def split_vertical
    if @grid_mode
      exit_grid_mode
    end
    
    if @active_pane
      new_pane = create_pane
      @container.split_vertical(@active_pane, new_pane)
      @active_pane = new_pane
      @active_pane.set_focus
    end
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

  def load_multiple_files(file_paths)
    return if file_paths.empty?
    
    # Очищаем существующие панели и контейнер
    @panes.clear
    @container.set_root_container(Gtk::Box.new(:vertical, 0))
    
    # Создаем grid-сетку
    create_grid_from_files(file_paths)
    
    # Устанавливаем первую панель как активную
    @active_pane = @panes.first
    @active_pane.set_focus if @active_pane
  end

  def load_directory(directory_path)
    return unless Dir.exist?(directory_path)
    
    # Получаем все файлы из директории
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

  def grid_mode?
    @grid_mode || false
  end

  private

  def setup_initial_pane
    @active_pane = create_pane
    @container.set_root(@active_pane)
    @grid_mode = false
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

  def create_grid_from_files(file_paths)
    return if file_paths.empty?
    
    # Вычисляем размеры grid
    total_files = file_paths.length
    cols = Math.sqrt(total_files).ceil
    rows = (total_files.to_f / cols).ceil
    
    puts "Creating grid: #{rows}x#{cols} for #{total_files} files"
    
    # Создаем панели для каждого файла
    file_paths.each_with_index do |file_path, index|
      pane = create_pane
      pane.load_file(file_path)
    end
    
    # Создаем grid-сетку
    create_grid_layout(rows, cols)
  end

  def create_grid_layout(rows, cols)
    return if @panes.empty?
    
    # Создаем строки
    row_containers = []
    rows.times do |row|
      row_start = row * cols
      row_panes = @panes[row_start, cols] || []
      next if row_panes.empty?
      
      if row_panes.size == 1
        # Одна панель в строке
        row_containers << row_panes.first.widget
      else
        # Создаем горизонтальную цепочку Paned для строки
        row_widget = create_horizontal_chain(row_panes)
        row_containers << row_widget
      end
    end
    
    # Создаем вертикальную цепочку для строк
    main_widget = if row_containers.size == 1
      row_containers.first
    else
      create_vertical_chain(row_containers)
    end
    
    # Удаляем виджеты из текущих родителей
    @panes.each do |pane|
      if pane.widget.parent
        pane.widget.parent.remove(pane.widget)
      end
    end
    
    # Создаем контейнер
    main_container = Gtk::Box.new(:vertical, 0)
    main_container.pack_start(main_widget, expand: true, fill: true, padding: 0)
    
    # Устанавливаем новый контейнер как корневой
    @container.set_root_container(main_container)
    
    # Помечаем что мы в grid режиме
    @grid_mode = true
  end
  
  def create_horizontal_chain(panes)
    return panes.first.widget if panes.size == 1
    
    # Создаем цепочку горизонтальных Paned
    root_paned = Gtk::Paned.new(:horizontal)
    root_paned.pack1(panes.first.widget, expand: true, shrink: false)
    
    current_paned = root_paned
    panes[1..-1].each_with_index do |pane, index|
      if index == panes.size - 2
        # Последняя панель
        current_paned.pack2(pane.widget, expand: true, shrink: false)
      else
        # Промежуточная панель
        new_paned = Gtk::Paned.new(:horizontal)
        new_paned.pack1(pane.widget, expand: true, shrink: false)
        current_paned.pack2(new_paned, expand: true, shrink: false)
        current_paned = new_paned
      end
    end
    
    # Устанавливаем равномерные позиции
    set_equal_positions(root_paned, panes.size)
    
    root_paned
  end
  
  def create_vertical_chain(widgets)
    return widgets.first if widgets.size == 1
    
    # Создаем цепочку вертикальных Paned
    root_paned = Gtk::Paned.new(:vertical)
    root_paned.pack1(widgets.first, expand: true, shrink: false)
    
    current_paned = root_paned
    widgets[1..-1].each_with_index do |widget, index|
      if index == widgets.size - 2
        # Последний виджет
        current_paned.pack2(widget, expand: true, shrink: false)
      else
        # Промежуточный виджет
        new_paned = Gtk::Paned.new(:vertical)
        new_paned.pack1(widget, expand: true, shrink: false)
        current_paned.pack2(new_paned, expand: true, shrink: false)
        current_paned = new_paned
      end
    end
    
    # Устанавливаем равномерные позиции
    set_equal_positions(root_paned, widgets.size)
    
    root_paned
  end
  
  def set_equal_positions(paned, total_items)
    # Устанавливаем позицию после показа окна
    GLib::Timeout.add(50) do
      if paned.allocated_width > 0 && paned.allocated_height > 0
        if paned.orientation == :horizontal
          position = paned.allocated_width / total_items
        else
          position = paned.allocated_height / total_items
        end
        paned.position = position
      end
      false # не повторять
    end
  end
  
  def exit_grid_mode
    return unless @grid_mode
    
    # Возвращаемся к обычному режиму с одной активной панелью
    if @active_pane
      @container.set_root(@active_pane)
      @panes = [@active_pane]
    else
      # Создаем новую панель если нет активной
      setup_initial_pane
    end
    
    @grid_mode = false
  end
end 