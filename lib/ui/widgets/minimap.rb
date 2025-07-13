require 'gtk3'
require 'cairo'

class Minimap < Gtk::DrawingArea
  def initialize(source_view)
    super()
    @source_view = source_view
    @buffer = source_view.buffer
    @line_height = 3
    @char_width = 1
    @visible_lines = 0
    @total_lines = 0
    @scroll_offset = 0
    
    setup_minimap
    connect_signals
  end

  private

  def setup_minimap
    set_size_request(100, -1)
    signal_connect("draw") { |widget, cr| draw_minimap(widget, cr) }
  end

  def connect_signals
    @buffer.signal_connect("changed") { queue_draw }
    @source_view.vadjustment.signal_connect("value-changed") { queue_draw }
    signal_connect("button-press-event") do |_, event|
      handle_click(event.x, event.y)
      true
    end
  end

  def draw_minimap(widget, cr)
    allocation = widget.allocation
    width = allocation.width
    height = allocation.height
    
    return false if @buffer.text.empty?
    
    cr.set_source_rgb(0.92, 0.92, 0.90)
    cr.paint
    cr.set_source_rgb(0.8, 0.8, 0.8)
    cr.set_line_width(1)
    cr.rectangle(0, 0, width, height)
    cr.stroke
    
    @total_lines = @buffer.line_count
    @visible_lines = height / @line_height
    @scroll_offset = @source_view.vadjustment.value
    
    lines = @buffer.text.split("\n")
    lines.each_with_index do |line, line_num|
      y = line_num * @line_height
      next if y + @line_height < 0 || y > height
      color = get_line_color(line)
      cr.set_source_rgb(*color)
      cr.rectangle(1, y, width - 2, @line_height)
      cr.fill
    end
    
    visible_start = @scroll_offset / @source_view.vadjustment.upper
    visible_height = (@source_view.vadjustment.page_size / @source_view.vadjustment.upper) * height
    visible_y = visible_start * height
    
    cr.set_source_rgba(0.2, 0.5, 0.9, 0.18)
    cr.rectangle(0, visible_y, width, visible_height)
    cr.fill
    cr.set_source_rgb(0.2, 0.5, 0.9)
    cr.set_line_width(1)
    cr.rectangle(0, visible_y, width, visible_height)
    cr.stroke
    
    false
  end

  def get_line_color(line)
    return [0.9, 0.9, 0.9] if line.strip.empty?
    if line.include?('def ') || line.include?('class ')
      [0.8, 0.6, 0.6]
    elsif line.include?('if ') || line.include?('while ') || line.include?('for ')
      [0.6, 0.8, 0.6]
    elsif line.include?('end')
      [0.6, 0.6, 0.8]
    else
      [0.85, 0.85, 0.85]
    end
  end

  def handle_click(x, y)
    line_num = (y / @line_height).to_i
    line_num = [[line_num, @total_lines - 1].min, 0].max
    iter = @buffer.get_iter_at(line: line_num)
    @source_view.scroll_to_iter(iter, 0.0, true, 0.0, 0.0)
  end
end 