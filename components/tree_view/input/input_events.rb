class InputEvents
  # Стандартные события ввода
  CLICK = :click
  DOUBLE_CLICK = :double_click
  KEY_PRESS = :key_press
  SCROLL = :scroll
  MOUSE_MOVE = :mouse_move
  
  # Стандартные клавиши
  KEY_UP = :up
  KEY_DOWN = :down
  KEY_LEFT = :left
  KEY_RIGHT = :right
  KEY_ENTER = :enter
  KEY_RETURN = :return
  KEY_SPACE = :space
  KEY_ESCAPE = :escape
  KEY_HOME = :home
  KEY_END = :end
  KEY_PAGE_UP = :page_up
  KEY_PAGE_DOWN = :page_down
  
  # Направления скролла
  SCROLL_UP = :scroll_up
  SCROLL_DOWN = :scroll_down
  SCROLL_LEFT = :scroll_left
  SCROLL_RIGHT = :scroll_right
  
  def self.normalize_key(key)
    case key
    when KEY_RETURN then KEY_ENTER
    else key
    end
  end
  
  def self.is_navigation_key?(key)
    [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_HOME, KEY_END, KEY_PAGE_UP, KEY_PAGE_DOWN].include?(key)
  end
  
  def self.is_action_key?(key)
    [KEY_ENTER, KEY_RETURN, KEY_SPACE].include?(key)
  end
end 