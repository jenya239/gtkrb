require 'gtk3'
require_relative '../../input/input_events'
require_relative '../../input/input_controller'

class GTK3EventAdapter
  def initialize(widget, input_controller)
    @widget = widget
    @input_controller = input_controller
    setup_events
  end
  
  def setup_events
    setup_mouse_events
    setup_keyboard_events
    setup_scroll_events
  end
  
  private
  
  def setup_mouse_events
    @widget.signal_connect("button-press-event") { |_, event| handle_gtk_click(event) }
    @widget.signal_connect("motion-notify-event") { |_, event| handle_gtk_motion(event) }
    @widget.signal_connect("leave-notify-event") { |_, event| handle_gtk_leave(event) }
    @widget.add_events(Gdk::EventMask::BUTTON_PRESS_MASK | 
                       Gdk::EventMask::POINTER_MOTION_MASK |
                       Gdk::EventMask::LEAVE_NOTIFY_MASK)
  end
  
  def setup_keyboard_events
    @widget.signal_connect("key-press-event") { |_, event| handle_gtk_key(event) }
    @widget.set_can_focus(true)
    @widget.add_events(Gdk::EventMask::KEY_PRESS_MASK)
  end
  
  def setup_scroll_events
    @widget.signal_connect("scroll-event") { |_, event| handle_gtk_scroll(event) }
    @widget.add_events(Gdk::EventMask::SCROLL_MASK)
  end
  
  def handle_gtk_click(event)
    result = @input_controller.handle_click(event.x, event.y, event.time / 1000.0)
    false  # Пропускаем событие дальше
  end
  
  def handle_gtk_motion(event)
    result = @input_controller.handle_mouse_move(event.x, event.y)
    false  # Пропускаем событие дальше
  end
  
  def handle_gtk_leave(event)
    @input_controller.handle_mouse_leave
    false # Пропускаем событие дальше
  end
  
  def handle_gtk_key(event)
    key = map_gtk_key(event.keyval)
    return false unless key
    
    result = @input_controller.handle_key_press(key)
    result  # Возвращаем true если событие обработано
  end
  
  def handle_gtk_scroll(event)
    direction = case event.direction
    when Gdk::ScrollDirection::UP
      InputEvents::SCROLL_UP
    when Gdk::ScrollDirection::DOWN
      InputEvents::SCROLL_DOWN
    when Gdk::ScrollDirection::LEFT
      InputEvents::SCROLL_LEFT
    when Gdk::ScrollDirection::RIGHT
      InputEvents::SCROLL_RIGHT
    else
      return false
    end
    
    result = @input_controller.handle_scroll(direction)
    result  # Возвращаем true если событие обработано
  end
  
  def map_gtk_key(keyval)
    case keyval
    when Gdk::Keyval::KEY_Up
      InputEvents::KEY_UP
    when Gdk::Keyval::KEY_Down
      InputEvents::KEY_DOWN
    when Gdk::Keyval::KEY_Left
      InputEvents::KEY_LEFT
    when Gdk::Keyval::KEY_Right
      InputEvents::KEY_RIGHT
    when Gdk::Keyval::KEY_Return
      InputEvents::KEY_RETURN
    when Gdk::Keyval::KEY_space
      InputEvents::KEY_SPACE
    when Gdk::Keyval::KEY_Escape
      InputEvents::KEY_ESCAPE
    when Gdk::Keyval::KEY_Home
      InputEvents::KEY_HOME
    when Gdk::Keyval::KEY_End
      InputEvents::KEY_END
    when Gdk::Keyval::KEY_Page_Up
      InputEvents::KEY_PAGE_UP
    when Gdk::Keyval::KEY_Page_Down
      InputEvents::KEY_PAGE_DOWN
    else
      nil
    end
  end
end 