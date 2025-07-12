#!/usr/bin/env ruby

require 'gtk4'
require 'cairo'
require 'gdk_pixbuf2'

ICON_FOLDER = GdkPixbuf::Pixbuf.new(file: "icons/folder.png", width: 14, height: 14)
ICON_FILE   = GdkPixbuf::Pixbuf.new(file: "icons/file.png",   width: 14, height: 14)
ICON_UP     = GdkPixbuf::Pixbuf.new(file: "icons/up.png",     width: 14, height: 14)

BG      = [0xfdf6e3, 0.97]
FG      = [0x657b83, 0.0]
CUR_BG  = [0xb58900, 0.15]
DIR_FG  = [0x268bd2, 0.0]
FILE_FG = [0x586e75, 0.0]
PARENT_FG = [0x859900, 0.0]

# Цвет в формате rgb (0..1)
def rgb(hex, alpha=0.0)
  r = ((hex >> 16) & 0xff) / 255.0
  g = ((hex >> 8) & 0xff) / 255.0
  b = (hex & 0xff) / 255.0
  [r, g, b, 1.0-alpha]
end

class SimpleCustomTree < Gtk::ScrolledWindow
  def initialize
    super()
    set_policy(:never, :automatic)
    @area = Gtk::DrawingArea.new
    @area.set_hexpand(true)
    @area.set_vexpand(true)
    set_child(@area)
    @selected_index = -1
    @hover_index = -1
    @item_height = 16
    @expanded = {}
    setup_events
    load_current_directory
  end

  private

  def setup_events
    click = Gtk::GestureClick.new
    click.signal_connect("pressed") do |gesture, n_press, x, y|
      idx = ((y + vscroll) / @item_height).to_i
      if idx.between?(0, @flat_items.size-1)
        @selected_index = idx
        @area.queue_draw
        item = @flat_items[idx]
        if item[:type] == :directory
          if n_press == 1
            toggle_expand(item[:path])
          elsif n_press == 2
            enter_dir(item[:path])
          end
        elsif item[:type] == :file && n_press == 1
          open_file(item[:path])
        elsif item[:type] == :parent && n_press == 2
          go_up
        end
      end
    end
    @area.add_controller(click)
    motion = Gtk::EventControllerMotion.new
    motion.signal_connect("motion") { |_,x,y| @hover_index = ((y + vscroll)/@item_height).to_i; @area.queue_draw }
    @area.add_controller(motion)
    leave = Gtk::EventControllerMotion.new
    leave.signal_connect("leave") { |_| @hover_index = -1; @area.queue_draw }
    @area.add_controller(leave)
    key = Gtk::EventControllerKey.new
    key.signal_connect("key-pressed") { |_,k,_,_| handle_key(k) }
    @area.add_controller(key)
    @area.set_draw_func { |_, cr, w, h| draw(cr, w, h) }
    # убираю set_content_width
  end

  def vscroll
    vadjustment ? vadjustment.value : 0
  end

  def handle_key(keyval)
    case keyval
    when Gdk::Keyval::KEY_Up
      @selected_index = [@selected_index-1, 0].max; @area.queue_draw
    when Gdk::Keyval::KEY_Down
      @selected_index = [@selected_index+1, @flat_items.size-1].min; @area.queue_draw
    when Gdk::Keyval::KEY_Return
      item = @flat_items[@selected_index]
      if item[:type] == :directory
        enter_dir(item[:path])
      elsif item[:type] == :file
        open_file(item[:path])
      elsif item[:type] == :parent
        go_up
      end
    end
  end

  def draw(cr, width, height)
    cr.set_source_rgba(*rgb(*BG)); cr.rectangle(0, 0, width, height); cr.fill
    y0 = vscroll
    @flat_items.each_with_index do |item, i|
      y = i*@item_height - y0
      next if y+@item_height < 0 || y > height
      # hover
      if i == @hover_index
        cr.set_source_rgba(0.87,0.91,0.95,0.7); cr.rectangle(0,y,width,@item_height); cr.fill
      end
      # selected
      if i == @selected_index
        cr.set_source_rgba(*rgb(*CUR_BG)); cr.rectangle(0,y,width,@item_height); cr.fill
      end
      # отступ
      xoff = item[:level]*12
      font_weight = Cairo::FONT_WEIGHT_NORMAL
      if item[:type] == :current
        font_weight = Cairo::FONT_WEIGHT_BOLD
        xoff = 0
      elsif item[:type] == :parent
        xoff = 0
      end
      # icon
      icon = case item[:type]
        when :parent then ICON_UP
        when :directory, :current then ICON_FOLDER
        else ICON_FILE
      end
      cr.save
      cr.translate(4 + xoff, y+1)
      cr.set_source_pixbuf(icon, 0, 0)
      cr.paint
      cr.restore
      # стрелка для папки
      if item[:type] == :directory && item[:children]
        cr.set_source_rgba(0.5,0.5,0.5,0.7)
        cr.set_line_width(1.5)
        cx = 16 + xoff; cy = y+8
        if @expanded[item[:path]]
          cr.move_to(cx-3, cy-1); cr.line_to(cx, cy+2); cr.line_to(cx+3, cy-1)
        else
          cr.move_to(cx-1, cy-3); cr.line_to(cx+2, cy); cr.line_to(cx-1, cy+3)
        end
        cr.stroke
      end
      # text
      fg = case item[:type]; when :parent then PARENT_FG; when :directory, :current then DIR_FG; else FILE_FG; end
      cr.set_source_rgba(*rgb(*fg))
      cr.select_font_face("Fira Mono", Cairo::FONT_SLANT_NORMAL, font_weight)
      cr.set_font_size(10)
      cr.move_to(22 + xoff, y+12)
      cr.show_text(item[:name])
    end
  end

  def load_current_directory
    @current_path = Dir.pwd
    @expanded = {}
    refresh_items
  end

  def refresh_items
    @tree_items = build_tree(@current_path, 0, true)
    @flat_items = flatten_tree(@tree_items)
    @selected_index = -1
    set_content_height
    @area.queue_draw
  end

  def set_content_height
    @area.set_height_request([@flat_items.size * @item_height, 1].max)
  end

  def build_tree(path, level, is_current=false)
    items = []
    parent = File.dirname(path)
    if parent != path && is_current
      items << { name: "..", path: "..", type: :parent, level: 0 }
    end
    if is_current
      items << { name: File.basename(path), path: path, type: :current, level: 0 }
    end
    Dir.children(path).sort.each do |e|
      next if e.start_with?('.')
      p = File.join(path, e)
      if File.directory?(p)
        children = nil
        if @expanded[p]
          children = build_tree(p, level+1, false)
        end
        items << { name: e, path: p, type: :directory, level: level+1, children: children }
      else
        items << { name: e, path: p, type: :file, level: level+1 }
      end
    end
    items
  end

  def flatten_tree(items)
    flat = []
    items.each do |item|
      flat << item.dup.tap { |h| h.delete(:children) }
      if item[:children]
        flat.concat(flatten_tree(item[:children]))
      end
    end
    flat
  end

  def toggle_expand(path)
    @expanded[path] = !@expanded[path]
    refresh_items
  end

  def enter_dir(path)
    @current_path = path
    @expanded = {}
    refresh_items
  end

  def go_up
    parent = File.dirname(@current_path)
    return if parent == @current_path
    @current_path = parent
    @expanded = {}
    refresh_items
  end

  def open_file(path)
    puts "File: #{path}"
  end

  public
  def refresh; refresh_items; end
  def get_selected_path; @flat_items[@selected_index]&.dig(:path); end
end 