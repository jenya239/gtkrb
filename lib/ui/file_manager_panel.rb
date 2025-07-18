require_relative 'base_panel'

class FileManagerPanel < BasePanel
  def initialize(root_dir = Dir.pwd)
    super(:file_manager)
    @root_dir = root_dir
    @current_dir = root_dir
    @tree_view = nil
    @store = nil
    @on_file_selected_callback = nil
    
    setup_file_manager
  end

  def setup_ui
    # Создаем заголовок с кнопками
    create_header
    
    # Добавляем файловый менеджер
    @box.pack_start(@tree_view, expand: true, fill: true, padding: 0)
  end

  def get_title
    "Files: #{File.basename(@current_dir)}"
  end

  def focus
    @tree_view.grab_focus if @tree_view
  end

  def can_close?
    true
  end

  def get_current_dir
    @current_dir
  end

  def set_current_dir(dir)
    @current_dir = dir
    refresh_tree
    update_title
  end

  def on_file_selected(&block)
    @on_file_selected_callback = block
  end

  def refresh_tree
    @store.clear
    populate_tree(@current_dir)
  end

  private

  def setup_file_manager
    # Создаем TreeView
    @store = Gtk::TreeStore.new(String, String, String) # name, path, type
    @tree_view = Gtk::TreeView.new(@store)
    @tree_view.set_headers_visible(false)
    
    # Колонка для имени файла
    renderer = Gtk::CellRendererText.new
    column = Gtk::TreeViewColumn.new("Name", renderer, text: 0)
    @tree_view.append_column(column)
    
    # Заполняем дерево
    populate_tree(@current_dir)
    
    # Обработчики событий
    @tree_view.signal_connect('row-activated') do |tree_view, path, column|
      iter = @store.get_iter(path)
      file_path = iter[1]
      file_type = iter[2]
      
      if file_type == 'directory'
        set_current_dir(file_path)
      else
        # Файл выбран
        @on_file_selected_callback.call(file_path) if @on_file_selected_callback
      end
    end

    # Контекстное меню
    @tree_view.signal_connect('button-press-event') do |widget, event|
      if event.button == 3  # правая кнопка мыши
        show_context_menu(event)
      end
    end
  end

  def populate_tree(dir)
    return unless Dir.exist?(dir)
    
    # Добавляем родительскую директорию
    if dir != @root_dir
      parent_dir = File.dirname(dir)
      iter = @store.append(nil)
      iter[0] = ".."
      iter[1] = parent_dir
      iter[2] = "directory"
    end
    
    # Добавляем содержимое директории
    begin
      entries = Dir.entries(dir).reject { |entry| entry.start_with?('.') }
      entries.sort.each do |entry|
        full_path = File.join(dir, entry)
        
        iter = @store.append(nil)
        
        if File.directory?(full_path)
          iter[0] = "📁 #{entry}"
          iter[1] = full_path
          iter[2] = "directory"
        else
          icon = get_file_icon(entry)
          iter[0] = "#{icon} #{entry}"
          iter[1] = full_path
          iter[2] = "file"
        end
      end
    rescue => e
      puts "Error reading directory #{dir}: #{e.message}"
    end
  end

  def get_file_icon(filename)
    ext = File.extname(filename).downcase
    
    case ext
    when '.rb'
      '💎'
    when '.py'
      '🐍'
    when '.js', '.ts'
      '📜'
    when '.html', '.htm'
      '🌐'
    when '.css'
      '🎨'
    when '.json'
      '📋'
    when '.xml'
      '📄'
    when '.md'
      '📝'
    when '.txt'
      '📄'
    when '.png', '.jpg', '.jpeg', '.gif'
      '🖼️'
    when '.mp3', '.wav', '.ogg'
      '🎵'
    when '.mp4', '.avi', '.mkv'
      '🎬'
    when '.zip', '.tar', '.gz'
      '📦'
    else
      '📄'
    end
  end

  def show_context_menu(event)
    menu = Gtk::Menu.new
    
    # Создать новый файл
    new_file_item = Gtk::MenuItem.new("New File")
    new_file_item.signal_connect('activate') do
      create_new_file
    end
    menu.append(new_file_item)
    
    # Создать новую папку
    new_folder_item = Gtk::MenuItem.new("New Folder")
    new_folder_item.signal_connect('activate') do
      create_new_folder
    end
    menu.append(new_folder_item)
    
    # Обновить
    refresh_item = Gtk::MenuItem.new("Refresh")
    refresh_item.signal_connect('activate') do
      refresh_tree
    end
    menu.append(refresh_item)
    
    menu.show_all
    menu.popup(nil, nil, event.button, event.time)
  end

  def create_new_file
    dialog = Gtk::Dialog.new(
      title: "New File",
      parent: nil,
      flags: :modal
    )
    
    dialog.add_button("Cancel", :cancel)
    dialog.add_button("Create", :accept)
    
    entry = Gtk::Entry.new
    entry.placeholder_text = "Enter filename"
    dialog.child.pack_start(entry, expand: true, fill: true, padding: 10)
    
    dialog.show_all
    
    if dialog.run == :accept
      filename = entry.text
      unless filename.empty?
        file_path = File.join(@current_dir, filename)
        File.write(file_path, "")
        refresh_tree
        @on_file_selected_callback.call(file_path) if @on_file_selected_callback
      end
    end
    
    dialog.destroy
  end

  def create_new_folder
    dialog = Gtk::Dialog.new(
      title: "New Folder",
      parent: nil,
      flags: :modal
    )
    
    dialog.add_button("Cancel", :cancel)
    dialog.add_button("Create", :accept)
    
    entry = Gtk::Entry.new
    entry.placeholder_text = "Enter folder name"
    dialog.child.pack_start(entry, expand: true, fill: true, padding: 10)
    
    dialog.show_all
    
    if dialog.run == :accept
      folder_name = entry.text
      unless folder_name.empty?
        folder_path = File.join(@current_dir, folder_name)
        Dir.mkdir(folder_path)
        refresh_tree
      end
    end
    
    dialog.destroy
  end

  def create_header
    header_box = Gtk::Box.new(:horizontal, 0)
    
    # Заголовок
    @title_label = Gtk::Label.new(get_title)
    @title_label.set_xalign(0.0)
    @title_label.override_color(:normal, Gdk::RGBA::new(0.9, 0.9, 0.9, 1.0))
    
    # Кнопки
    buttons_box = create_button_bar
    
    # Кнопки для файлового менеджера
    buttons_box.pack_start(create_button("⊞", :focus, "Focus"), expand: false, fill: false, padding: 1)
    buttons_box.pack_start(create_button("❙", :split_vertical, "Split Vertical"), expand: false, fill: false, padding: 1)
    buttons_box.pack_start(create_button("═", :split_horizontal, "Split Horizontal"), expand: false, fill: false, padding: 1)
    buttons_box.pack_start(create_button("🔄", :refresh, "Refresh"), expand: false, fill: false, padding: 1)
    buttons_box.pack_start(create_button("📝", :new_file, "New Editor"), expand: false, fill: false, padding: 1)
    buttons_box.pack_start(create_button("✗", :close, "Close"), expand: false, fill: false, padding: 1)
    
    header_box.pack_start(@title_label, expand: true, fill: true, padding: 5)
    header_box.pack_start(buttons_box, expand: false, fill: false, padding: 2)
    
    @box.pack_start(header_box, expand: false, fill: false, padding: 0)
  end

  def update_title
    @title_label.text = get_title if @title_label
  end

  def handle_button_click(action)
    case action
    when :refresh
      refresh_tree
    else
      super(action)
    end
  end
end 