class TreeTheme
  attr_reader :item_height, :indent_size, :icon_size, :font_size
  
  def initialize
    @item_height = 16
    @indent_size = 10
    @icon_size = 10
    @font_size = 9
    @left_margin = 6
  end
  
  def background_color
    [0.992, 0.965, 0.890, 1.0]  # Solarized base3
  end
  
  def item_background_color
    [0.992, 0.965, 0.890, 1.0]  # Solarized base3
  end
  
  def selection_color
    [0.345, 0.431, 0.459, 0.12]  # Solarized base01 with transparency
  end
  
  def hover_color
    [0.345, 0.431, 0.459, 0.06]  # Solarized base01 with less transparency
  end
  
  def text_color
    [0.345, 0.431, 0.459, 1.0]  # Solarized base01
  end
  
  def expander_color
    [0.514, 0.580, 0.588, 1.0]  # Solarized base0
  end
  
  def border_color
    [0.835, 0.835, 0.835, 1.0]  # Light border
  end
  
  def icon_color
    [0.710, 0.537, 0.000, 0.7]  # Solarized yellow, lighter
  end
  
  def folder_color
    [0.149, 0.545, 0.824, 0.7]  # Solarized blue, lighter
  end
  
  def parent_color
    [0.514, 0.580, 0.588, 0.7]  # Solarized base0, lighter
  end
  
  # Расчет позиций
  def icon_x(level)
    @left_margin + level * @indent_size
  end
  
  def text_x(level)
    icon_x(level) + @icon_size + 3
  end
  
  def text_y(item_y)
    # Центрируем текст по вертикали: центр элемента + небольшое смещение для baseline
    item_y + @item_height / 2 + @font_size / 4
  end
  
  def icon_y(item_y)
    # Центрируем иконку по вертикали
    item_y + (@item_height - @icon_size) / 2
  end
end 