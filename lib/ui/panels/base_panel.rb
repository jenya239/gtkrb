require 'gtk3'

class BasePanel
  attr_reader :panel_id, :panel_type

  def initialize(panel_type)
    @panel_id = "panel_#{object_id}"
    @panel_type = panel_type
    @box = Gtk::Box.new(:vertical, 0)
    @active = false
    
    # Callbacks
    @on_focus_callback = nil
    @on_modified_callback = nil
    @on_button_callback = nil
    @on_close_callback = nil
    @on_split_h_callback = nil
    @on_split_v_callback = nil
    @on_new_file_callback = nil
    @on_save_callback = nil
    @on_file_saved_callback = nil
    @on_history_callback = nil
    
    setup_ui
  end

  def widget
    @box
  end

  # Абстрактные методы - должны быть реализованы в подклассах
  def setup_ui
    raise NotImplementedError, "#{self.class} должен реализовать setup_ui"
  end

  def get_title
    raise NotImplementedError, "#{self.class} должен реализовать get_title"
  end

  def can_close?
    true
  end

  def has_unsaved_changes?
    false
  end

  def save
    # По умолчанию ничего не делаем
  end

  def focus
    # По умолчанию ничего не делаем
  end

  # Методы для callbacks
  def on_focus(&block)
    @on_focus_callback = block
  end

  def on_modified(&block)
    @on_modified_callback = block
  end

  def on_button(&block)
    @on_button_callback = block
  end

  def on_close(&block)
    @on_close_callback = block
  end

  def on_split_horizontal(&block)
    @on_split_h_callback = block
  end

  def on_split_vertical(&block)
    @on_split_v_callback = block
  end

  def on_new_file(&block)
    @on_new_file_callback = block
  end

  def on_save(&block)
    @on_save_callback = block
  end

  def on_file_saved(&block)
    @on_file_saved_callback = block
  end

  def on_history(&block)
    @on_history_callback = block
  end

  # Методы для управления стилем
  def set_active_style
    @active = true
    @box.override_background_color(:normal, Gdk::RGBA::new(0.2, 0.2, 0.2, 1.0))
  end

  def set_inactive_style
    @active = false
    @box.override_background_color(:normal, Gdk::RGBA::new(0.15, 0.15, 0.15, 1.0))
  end

  def set_focus
    @on_focus_callback.call(self) if @on_focus_callback
  end

  protected

  def emit_modified
    @on_modified_callback.call if @on_modified_callback
  end

  def emit_button_click
    @on_button_callback.call(self) if @on_button_callback
  end

  def create_button_bar
    # Создаем панель кнопок
    buttons_box = Gtk::Box.new(:horizontal, 2)
    buttons_box.set_size_request(-1, 24)
    
    # Кнопки будут добавляться в подклассах
    @buttons_box = buttons_box
    buttons_box
  end

  def create_button(icon_text, action, tooltip = nil)
    button = Gtk::Button.new
    button.set_size_request(20, 20)
    button.label = icon_text
    button.tooltip_text = tooltip if tooltip
    button.instance_variable_set(:@action, action)
    
    # Темная тема
    button.override_background_color(:normal, Gdk::RGBA::new(0.3, 0.3, 0.3, 1.0))
    button.override_color(:normal, Gdk::RGBA::new(0.9, 0.9, 0.9, 1.0))
    
    button.signal_connect('clicked') do
      handle_button_click(action)
    end
    
    button
  end

  def handle_button_click(action)
    case action
    when :focus
      set_focus
    when :close
      @on_close_callback.call(self) if @on_close_callback
    when :split_horizontal
      @on_split_h_callback.call(self) if @on_split_h_callback
    when :split_vertical
      @on_split_v_callback.call(self) if @on_split_v_callback
    when :new_file
      @on_new_file_callback.call(self) if @on_new_file_callback
    when :save
      @on_save_callback.call(self) if @on_save_callback
    when :history
      @on_history_callback.call(self) if @on_history_callback
    end
  end
end 