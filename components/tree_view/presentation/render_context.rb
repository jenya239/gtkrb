class RenderContext
  attr_reader :width, :height, :theme, :icon_loader
  
  def initialize(width, height, theme, icon_loader = nil)
    @width = width
    @height = height
    @theme = theme
    @icon_loader = icon_loader
  end
  
  def draw_rectangle(x, y, width, height, color)
    raise NotImplementedError, "Subclasses must implement draw_rectangle"
  end
  
  def draw_text(x, y, text, font_size, color)
    raise NotImplementedError, "Subclasses must implement draw_text"
  end
  
  def draw_icon(x, y, icon_type)
    raise NotImplementedError, "Subclasses must implement draw_icon"
  end
  
  def draw_line(x1, y1, x2, y2, color, width = 1)
    raise NotImplementedError, "Subclasses must implement draw_line"
  end
  
  def clear_background(color)
    raise NotImplementedError, "Subclasses must implement clear_background"
  end
end 