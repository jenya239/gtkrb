#!/usr/bin/env ruby

# Упрощенный тест множественных файловых деревьев (без терминала)

require 'gtk3'
require_relative 'lib/ui/panel_manager'
require_relative 'lib/ui/split_container'

class TestMultipleTreesSimple
  def initialize
    @window = Gtk::Window.new
    @window.set_title("GTKRB - Multiple File Trees Test (Simple)")
    @window.set_default_size(1400, 800)
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
    @status_bar.push(0, "Ready - Test multiple file trees (simple version)")
    vbox.pack_start(@status_bar, expand: false, fill: false, padding: 0)
    
    @window.add(vbox)
    @window.show_all
  end

  def create_menu_bar
    menu_bar = Gtk::MenuBar.new
    
    # File menu
    file_menu = Gtk::Menu.new
    file_item = Gtk::MenuItem.new(label: "File")
    file_item.set_submenu(file_menu)
    
    # Создать файловые деревья
    create_trees_item = Gtk::MenuItem.new(label: "Create Multiple Trees")
    create_trees_item.signal_connect("activate") { create_test_trees }
    file_menu.append(create_trees_item)
    
    # Переключение типов (только редактор и файловое дерево)
    convert_menu = Gtk::Menu.new
    convert_item = Gtk::MenuItem.new(label: "Convert Panel")
    convert_item.set_submenu(convert_menu)
    
    to_editor_item = Gtk::MenuItem.new(label: "To Editor")
    to_editor_item.signal_connect("activate") { @panel_manager.convert_active_to_editor }
    convert_menu.append(to_editor_item)
    
    to_file_manager_item = Gtk::MenuItem.new(label: "To File Manager")
    to_file_manager_item.signal_connect("activate") { @panel_manager.convert_active_to_file_manager }
    convert_menu.append(to_file_manager_item)
    
    file_menu.append(convert_item)
    menu_bar.append(file_item)
    
    # Test menu
    test_menu = Gtk::Menu.new
    test_item = Gtk::MenuItem.new(label: "Test")
    test_item.set_submenu(test_menu)
    
    show_info_item = Gtk::MenuItem.new(label: "Show File Trees Info")
    show_info_item.signal_connect("activate") { show_file_trees_info }
    test_menu.append(show_info_item)
    
    menu_bar.append(test_item)
    
    menu_bar
  end

  def create_test_trees
    # Создаем несколько файловых деревьев в разных директориях
    directories = [
      Dir.pwd,
      File.expand_path("~/Documents"),
      File.expand_path("~/"),
      "/tmp"
    ].select { |dir| Dir.exist?(dir) }
    
    if directories.size > 1
      @panel_manager.create_multiple_file_managers(directories)
      @status_bar.push(0, "Created #{directories.size} file trees")
    else
      @status_bar.push(0, "Not enough directories available")
    end
  end

  def show_file_trees_info
    trees = @panel_manager.get_file_trees
    
    dialog = Gtk::MessageDialog.new(
      parent: @window,
      flags: :destroy_with_parent,
      type: :info,
      buttons_type: :ok,
      message: "Active File Trees:\n\n#{format_trees_info(trees)}"
    )
    
    dialog.run
    dialog.destroy
  end

  def format_trees_info(trees)
    if trees.empty?
      "No active file trees"
    else
      trees.map { |id, info| "Panel #{id}: #{info[:root_dir]}" }.join("\n")
    end
  end

  def show_usage
    puts "\n=== Multiple File Trees Test (Simple) ==="
    puts "1. File > Create Multiple Trees - creates file managers for different directories"
    puts "2. File > Convert Panel - converts active panel to editor or file manager"
    puts "3. Test > Show File Trees Info - shows active file trees"
    puts "4. Click files in any tree to open them in active editor"
    puts "5. Use 📁 and 📄 buttons in panel headers to convert panel types"
    puts "6. Terminal support disabled in this simple version"
    puts "============================================\n"
  end
end

# Запуск тестов
if __FILE__ == $0
  test = TestMultipleTreesSimple.new
  Gtk.main
end 