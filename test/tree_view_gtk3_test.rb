#!/usr/bin/env ruby

require 'gtk3'
require_relative '../lib/ui/widgets/tree_view'

# Простой источник данных для тестирования
class TestDataSource < TreeDataSource
  def initialize
    @items = [
      OpenStruct.new(name: "Item 1", children: [
        OpenStruct.new(name: "Item 1.1", children: []),
        OpenStruct.new(name: "Item 1.2", children: [])
      ]),
      OpenStruct.new(name: "Item 2", children: [
        OpenStruct.new(name: "Item 2.1", children: []),
        OpenStruct.new(name: "Item 2.2", children: [])
      ])
    ]
  end

  def get_root_items
    @items
  end

  def get_children(parent_item)
    parent_item.children || []
  end

  def can_expand?(item)
    item.children && !item.children.empty?
  end
end

class TestWindow < Gtk::Window
  def initialize
    super
    set_title("GTK3 TreeView Test")
    set_default_size(400, 300)
    signal_connect("destroy") { Gtk.main_quit }

    # Создаем scrolled window
    scrolled = Gtk::ScrolledWindow.new
    add(scrolled)

    data_source = TestDataSource.new
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