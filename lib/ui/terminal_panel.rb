require_relative 'base_panel'
require 'vte3'

class TerminalPanel < BasePanel
  def initialize(working_dir = Dir.pwd)
    super(:terminal)
    @working_dir = working_dir
    @terminal = nil
    @terminal_widget = nil
    
    setup_terminal
  end

  def setup_ui
    # Создаем заголовок с кнопками
    create_header
    
    # Добавляем терминал
    @box.pack_start(@terminal_widget, expand: true, fill: true, padding: 0)
  end

  def get_title
    "Terminal: #{File.basename(@working_dir)}"
  end

  def focus
    @terminal.grab_focus if @terminal
  end

  def can_close?
    true
  end

  def get_working_dir
    @working_dir
  end

  def set_working_dir(dir)
    @working_dir = dir
    update_title
  end

  def execute_command(command)
    return unless @terminal
    
    # Отправляем команду в терминал
    @terminal.feed_child("#{command}\n")
  end

  private

  def setup_terminal
    @terminal = Vte::Terminal.new
    @terminal_widget = Gtk::ScrolledWindow.new
    @terminal_widget.set_policy(:automatic, :automatic)
    @terminal_widget.add(@terminal)
    
    # Настройка терминала
    @terminal.set_size(80, 24)
    @terminal.set_scrollback_lines(1000)
    
    # Темная тема
    @terminal.set_colors(
      Gdk::RGBA::new(0.9, 0.9, 0.9, 1.0),  # foreground
      Gdk::RGBA::new(0.1, 0.1, 0.1, 1.0),  # background
      []                                     # palette
    )
    
    # Запуск shell
    spawn_shell
  end

  def spawn_shell
    begin
      @terminal.spawn_sync(
        0,                                    # flags
        @working_dir,                         # working directory
        [ENV['SHELL'] || '/bin/bash'],        # command
        nil,                                  # environment
        0                                     # spawn flags
      )
      puts "Terminal spawned successfully in #{@working_dir}"
    rescue => e
      puts "Error spawning terminal: #{e.message}"
    end
  end

  def create_header
    header_box = Gtk::Box.new(:horizontal, 0)
    
    # Заголовок
    @title_label = Gtk::Label.new(get_title)
    @title_label.set_xalign(0.0)
    @title_label.override_color(:normal, Gdk::RGBA::new(0.9, 0.9, 0.9, 1.0))
    
    # Кнопки
    buttons_box = create_button_bar
    
    # Кнопки для терминала
    buttons_box.pack_start(create_button("⊞", :focus, "Focus"), expand: false, fill: false, padding: 1)
    buttons_box.pack_start(create_button("❙", :split_vertical, "Split Vertical"), expand: false, fill: false, padding: 1)
    buttons_box.pack_start(create_button("═", :split_horizontal, "Split Horizontal"), expand: false, fill: false, padding: 1)
    buttons_box.pack_start(create_button("🔄", :restart, "Restart Terminal"), expand: false, fill: false, padding: 1)
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
    when :restart
      restart_terminal
    else
      super(action)
    end
  end

  def restart_terminal
    # Перезапускаем терминал
    @terminal_widget.remove(@terminal) if @terminal
    setup_terminal
    @terminal_widget.add(@terminal)
    @terminal_widget.show_all
  end
end 