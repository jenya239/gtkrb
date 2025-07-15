require_relative 'tree_theme'

class MatrixGigerTheme < TreeTheme
  def initialize
    super
    # Немного увеличиваем размеры для драматического эффекта
    @item_height = 18
    @font_size = 10
    @left_margin = 8
  end
  
  # === MATRIX/HACKER COLORS ===
  
  def background_color
    [0.05, 0.05, 0.05, 1.0]  # Глубокий черный фон (матрица)
  end
  
  def item_background_color
    [0.08, 0.08, 0.08, 1.0]  # Чуть светлее черного
  end
  
  def text_color
    [0.0, 1.0, 0.2, 0.9]  # Яркий матричный зеленый #00ff33
  end
  
  def selection_color
    [1.0, 0.0, 0.0, 0.25]  # Красная биомеханическая подсветка (Giger)
  end
  
  def hover_color
    [0.0, 0.8, 0.2, 0.15]  # Слабое зеленое свечение при hover
  end
  
  # === GIGER METALLIC ACCENTS ===
  
  def border_color
    [0.3, 0.3, 0.35, 1.0]  # Темный металлический серый
  end
  
  def expander_color
    [0.6, 0.6, 0.7, 1.0]  # Светлый металлический
  end
  
  # === ICON COLORS (cyberpunk palette) ===
  
  def icon_color
    [0.0, 0.9, 0.9, 0.8]  # Киберпанк cyan для файлов
  end
  
  def folder_color
    [0.2, 1.0, 0.2, 0.8]  # Матричный зеленый для папок
  end
  
  def parent_color
    [1.0, 0.3, 0.0, 0.8]  # Красно-оранжевый для ".." (Giger accent)
  end
  
  # === ADDITIONAL CYBERPUNK EFFECTS ===
  
  def warning_color
    [1.0, 0.8, 0.0, 0.7]  # Желтый для предупреждений
  end
  
  def error_color
    [1.0, 0.1, 0.1, 0.9]  # Ярко-красный для ошибок
  end
  
  def success_color
    [0.0, 1.0, 0.0, 0.8]  # Ярко-зеленый для успеха
  end
  
  # Дополнительные эффекты для будущего использования
  def glow_color
    [0.0, 1.0, 0.2, 0.3]  # Зеленое свечение
  end
  
  def metal_dark
    [0.15, 0.15, 0.18, 1.0]  # Темный металл Gигера
  end
  
  def metal_light
    [0.4, 0.4, 0.45, 1.0]  # Светлый металл
  end
  
  # === OVERRIDDEN POSITIONING (для драматического эффекта) ===
  
  def text_y(item_y)
    # Чуть выше центра для более агрессивного вида
    item_y + @item_height / 2 + @font_size / 3
  end
  
  def icon_y(item_y)
    # Центрируем иконки
    item_y + (@item_height - @icon_size) / 2
  end
end 