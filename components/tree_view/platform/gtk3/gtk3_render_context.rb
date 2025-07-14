require 'cairo'
require_relative '../../presentation/render_context'
require_relative 'gtk3_icon_loader'

class GTK3RenderContext < RenderContext
  attr_reader :cairo
  
  def initialize(cairo_context, width, height, theme)
    @cairo = cairo_context
    @icon_loader = GTK3IconLoader.new
    super(width, height, theme, @icon_loader)
  end
  
  def draw_rectangle(x, y, width, height, color)
    @cairo.set_source_rgba(*color)
    @cairo.rectangle(x, y, width, height)
    @cairo.fill
  end
  
  def draw_text(x, y, text, font_size, color)
    @cairo.set_source_rgba(*color)
    @cairo.select_font_face("Sans", Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
    @cairo.set_font_size(font_size)
    @cairo.move_to(x, y)
    @cairo.show_text(text)
  end
  
  def draw_icon(x, y, icon_type)
    icon = @icon_loader.get_icon(icon_type)
    return unless icon
    
    @cairo.set_source_pixbuf(icon, x, y)
    @cairo.paint
  end
  
  def draw_line(x1, y1, x2, y2, color, width = 1)
    @cairo.set_source_rgba(*color)
    @cairo.set_line_width(width)
    @cairo.move_to(x1, y1)
    @cairo.line_to(x2, y2)
    @cairo.stroke
  end
  
  def draw_triangle(x1, y1, x2, y2, x3, y3, color)
    @cairo.set_source_rgba(*color)
    @cairo.move_to(x1, y1)
    @cairo.line_to(x2, y2)
    @cairo.line_to(x3, y3)
    @cairo.close_path
    @cairo.fill
  end
  
  def clear_background(color)
    @cairo.set_source_rgba(*color)
    @cairo.rectangle(0, 0, @width, @height)
    @cairo.fill
  end
  
  def draw_folder_icon(x, y, color)
    @cairo.set_source_rgba(*color)
    @cairo.set_line_width(0.8)
    
    # Рисуем папку как маленькую трапецию
    @cairo.move_to(x, y + 2)
    @cairo.line_to(x + 2, y)
    @cairo.line_to(x + 8, y)
    @cairo.line_to(x + 8, y + 7)
    @cairo.line_to(x, y + 7)
    @cairo.close_path
    @cairo.fill_preserve
    @cairo.set_line_width(0.5)
    @cairo.stroke
  end
  
  def draw_file_icon(x, y, color)
    @cairo.set_source_rgba(*color)
    @cairo.set_line_width(0.8)
    
    # Рисуем файл как маленький прямоугольник с загнутым углом
    @cairo.move_to(x, y)
    @cairo.line_to(x + 5, y)
    @cairo.line_to(x + 7, y + 1.5)
    @cairo.line_to(x + 7, y + 8)
    @cairo.line_to(x, y + 8)
    @cairo.close_path
    @cairo.fill_preserve
    @cairo.set_line_width(0.5)
    @cairo.stroke
  end
  
  def draw_up_arrow(x, y, color)
    @cairo.set_source_rgba(*color)
    @cairo.set_line_width(0.8)
    
    # Рисуем маленькую стрелку вверх
    @cairo.move_to(x + 3, y + 1)
    @cairo.line_to(x + 5, y + 4)
    @cairo.line_to(x + 4, y + 4)
    @cairo.line_to(x + 4, y + 7)
    @cairo.line_to(x + 2, y + 7)
    @cairo.line_to(x + 2, y + 4)
    @cairo.line_to(x + 1, y + 4)
    @cairo.close_path
    @cairo.fill
  end
end 