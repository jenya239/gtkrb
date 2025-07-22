#!/usr/bin/env ruby

# Тест новой архитектуры панелей

require 'gtk3'
require_relative 'lib/ui/panel_factory'
require_relative 'lib/ui/panel_manager'
require_relative 'lib/ui/split_container'

class TestPanelArchitecture
  def initialize
    @window = Gtk::Window.new
    @window.set_title("GTKRB - Test Panel Architecture")
    @window.set_default_size(1200, 800)
    @window.signal_connect("destroy") { Gtk.main_quit }
    
    setup_ui
    show_usage
  end

  def setup_ui
    # Главный контейнер
    vbox = Gtk::Box.new(:vertical, 0)
    
    # Меню для тестирования
    menu_bar = create_menu_bar
    vbox.pack_start(menu_bar, expand: false, fill: false, padding: 0)
    
    # Панель менеджер
    @container = SplitContainer.new
    @panel_manager = PanelManager.new(@container)
    
    vbox.pack_start(@panel_manager.widget, expand: true, fill: true, padding: 0)
    
    # Статус бар
    @status_bar = Gtk::Statusbar.new
    @status_bar.push(0, "Ready - Use menu to test different panel types")
    vbox.pack_start(@status_bar, expand: false, fill: false, padding: 0)
    
    @window.add(vbox)
    @window.show_all
  end

  def create_menu_bar
    menu_bar = Gtk::MenuBar.new
    
    # Панели меню
    panels_menu = Gtk::Menu.new
    panels_item = Gtk::MenuItem.new("Panels")
    panels_item.submenu = panels_menu
    
    # Пункты меню
    create_editor_item = Gtk::MenuItem.new("New Editor")
    create_editor_item.signal_connect("activate") { create_editor }
    panels_menu.append(create_editor_item)
    
    create_terminal_item = Gtk::MenuItem.new("New Terminal")
    create_terminal_item.signal_connect("activate") { create_terminal }
    panels_menu.append(create_terminal_item)
    
    create_file_manager_item = Gtk::MenuItem.new("New File Manager")
    create_file_manager_item.signal_connect("activate") { create_file_manager }
    panels_menu.append(create_file_manager_item)
    
    panels_menu.append(Gtk::SeparatorMenuItem.new)
    
    load_file_item = Gtk::MenuItem.new("Load File...")
    load_file_item.signal_connect("activate") { load_file }
    panels_menu.append(load_file_item)
    
    # Разделение меню
    split_menu = Gtk::Menu.new
    split_item = Gtk::MenuItem.new("Split")
    split_item.submenu = split_menu
    
    split_h_item = Gtk::MenuItem.new("Split Horizontal")
    split_h_item.signal_connect("activate") { @panel_manager.split_horizontal }
    split_menu.append(split_h_item)
    
    split_v_item = Gtk::MenuItem.new("Split Vertical")
    split_v_item.signal_connect("activate") { @panel_manager.split_vertical }
    split_menu.append(split_v_item)
    
    # Режимы меню
    mode_menu = Gtk::Menu.new
    mode_item = Gtk::MenuItem.new("Mode")
    mode_item.submenu = mode_menu
    
    grid_mode_item = Gtk::MenuItem.new("Grid Mode")
    grid_mode_item.signal_connect("activate") { toggle_grid_mode }
    mode_menu.append(grid_mode_item)
    
    # Добавляем в меню бар
    menu_bar.append(panels_item)
    menu_bar.append(split_item)
    menu_bar.append(mode_item)
    
    menu_bar
  end

  def create_editor
    @panel_manager.create_editor_panel
    @status_bar.push(0, "Created new editor panel")
  end

  def create_terminal
    @panel_manager.create_terminal_panel
    @status_bar.push(0, "Created new terminal panel")
  end

  def create_file_manager
    @panel_manager.create_file_manager_panel
    @status_bar.push(0, "Created new file manager panel")
  end

  def load_file
    dialog = Gtk::FileChooserDialog.new(
      title: "Load File",
      parent: @window,
      action: :open,
      buttons: [
        [Gtk::Stock::CANCEL, :cancel],
        [Gtk::Stock::OPEN, :accept]
      ]
    )
    
    if dialog.run == :accept
      filename = dialog.filename
      @panel_manager.load_file(filename)
      @status_bar.push(0, "Loaded file: #{File.basename(filename)}")
    end
    
    dialog.destroy
  end

  def toggle_grid_mode
    if @panel_manager.grid_mode?
      @panel_manager.exit_grid_mode
      @status_bar.push(0, "Exited grid mode")
    else
      @panel_manager.enter_grid_mode
      @status_bar.push(0, "Entered grid mode")
    end
  end

  def show_usage
    puts "=== GTKRB Panel Architecture Test ==="
    puts
    puts "Supported panel types:"
    puts "- Editor: Text editor with syntax highlighting"
    puts "- Terminal: VTE terminal with shell"
    puts "- File Manager: File browser with icons"
    puts
    puts "Features to test:"
    puts "- Create different panel types"
    puts "- Split panels horizontally/vertically"
    puts "- Grid mode for multiple panels"
    puts "- File history dropdown (editor panels)"
    puts "- Context menus (file manager)"
    puts "- Terminal restart (terminal panels)"
    puts
    puts "Panel buttons:"
    puts "- ⊞ Focus - set focus to panel"
    puts "- ❙ Split Vertical - split panel vertically"
    puts "- ═ Split Horizontal - split panel horizontally"
    puts "- ⏷ File History - show file history (editor only)"
    puts "- 💾 Save - save file (editor only)"
    puts "- 🔄 Restart/Refresh - restart terminal or refresh files"
    puts "- 📝 New Editor - create new editor panel"
    puts "- ✗ Close - close panel"
    puts
    puts "Use the menu bar to test different features!"
  end

  def run
    Gtk.main
  end
end

# Запуск теста
if __FILE__ == $0
  test = TestPanelArchitecture.new
  test.run
end 