#!/usr/bin/env ruby

require 'gtk3'
require_relative '../lib/ui/widgets/tree_view'

# DataSource с ленивой загрузкой
class BigDataSource < TreeDataSource
  def initialize
    @root = (1..1000).map { |i| lazy_node("Folder #{i}", 2) }
  end

  def lazy_node(name, depth)
    OpenStruct.new(
      name: name,
      depth: depth,
      children: nil # Ленивая загрузка
    )
  end

  def get_root_items
    @root
  end

  def get_children(parent_item)
    return [] unless parent_item.depth > 0
    
    # Создаем детей только при запросе
    (1..100).map { |j| lazy_node("#{parent_item.name}/#{j}", parent_item.depth - 1) }
  end

  def can_expand?(item)
    item.depth > 0
  end
end

class TestWindow < Gtk::Window
  def initialize
    super
    set_title("GTK3 TreeView Stress Test - Lazy Loading")
    set_default_size(800, 600)
    signal_connect("destroy") { Gtk.main_quit }

    # Создаем scrolled window
    scrolled = Gtk::ScrolledWindow.new
    add(scrolled)

    data_source = BigDataSource.new
    @tree_view = TreeView.new(data_source)

    # Добавляем tree view в scrolled window
    scrolled.add(@tree_view)

    show_all
  end
end

if __FILE__ == $0
  window = TestWindow.new
  Gtk.main
end 