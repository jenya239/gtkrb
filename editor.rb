require 'gtk4'
require 'gtksourceview5'

# Принудительно устанавливаем тему Adwaita для GTK4
ENV['GTK_THEME'] = 'Adwaita'

# Отключаем вывод предупреждений GTK
ENV['G_MESSAGES_DEBUG'] = 'none'

class FileExplorer
  def initialize
    @store = Gtk::TreeStore.new(String, String)  # name, full_path
    @tree = Gtk::TreeView.new(@store)
    setup_tree_view
    load_project_structure
  end

  def widget
    scrolled = Gtk::ScrolledWindow.new
    scrolled.set_child(@tree)
    scrolled.set_size_request(250, -1)
    scrolled
  end

  def on_file_selected(&block)
    @on_file_selected = block
  end

  private

  def setup_tree_view
    # Колонка с иконками и названиями
    renderer = Gtk::CellRendererText.new
    column = Gtk::TreeViewColumn.new("Files", renderer, text: 0)
    @tree.append_column(column)
    
    # Обработка кликов
    @tree.selection.signal_connect("changed") do |selection|
      selected_rows = selection.selected_rows
      if !selected_rows.empty?
        path = selected_rows.first.first
        iter = @store.get_iter(path)
        if iter
          full_path = @store.get_value(iter, 1)
          @on_file_selected&.call(full_path) if File.file?(full_path)
        end
      end
    end
  end

  def load_project_structure
    root_path = Dir.pwd
    build_tree(nil, root_path, File.basename(root_path))
    @tree.expand_all
  end

  def build_tree(parent, path, name)
    return unless Dir.exist?(path)
    
    iter = @store.append(parent)
    @store.set_value(iter, 0, name)
    @store.set_value(iter, 1, path)
    
    Dir.children(path).sort.each do |entry|
      next if entry.start_with?('.')  # Пропускаем скрытые файлы
      full_path = File.join(path, entry)
      build_tree(iter, full_path, entry) if File.directory?(full_path)
      
      if File.file?(full_path)
        file_iter = @store.append(iter)
        @store.set_value(file_iter, 0, entry)
        @store.set_value(file_iter, 1, full_path)
      end
    end
  end
end

app = Gtk::Application.new("org.example.editor", :default_flags)
app.signal_connect "activate" do |application|
  win = Gtk::ApplicationWindow.new(application)
  win.set_title("Editor")
  win.set_default_size(1200, 700)
  
  # Создаем файловый эксплорер
  file_explorer = FileExplorer.new
  
  # Создаем основной редактор
  view = GtkSource::View.new
  buffer = view.buffer
  manager = GtkSource::LanguageManager.new
  
  # Оборачиваем редактор в прокручиваемое окно
  editor_scrolled = Gtk::ScrolledWindow.new
  editor_scrolled.set_child(view)
  
  # Обработчик выбора файла
  file_explorer.on_file_selected do |file_path|
    begin
      content = File.read(file_path)
      buffer.text = content
      
      # Определяем язык по расширению
      ext = File.extname(file_path).downcase
      language_map = {
        '.rb' => 'ruby',
        '.py' => 'python', 
        '.js' => 'javascript',
        '.html' => 'html',
        '.css' => 'css',
        '.json' => 'json'
      }
      
      lang = language_map[ext]
      buffer.language = manager.get_language(lang) if lang
      
      view.set_show_line_numbers(true)
      view.set_highlight_current_line(true)
    rescue => e
      buffer.text = "# Error reading file: #{e.message}"
    end
  end
  
  # Создаем горизонтальный layout
  paned = Gtk::Paned.new(:horizontal)
  paned.set_start_child(file_explorer.widget)
  paned.set_end_child(editor_scrolled)
  paned.set_position(250)
  
  win.set_child(paned)
  win.present
end

app.run 