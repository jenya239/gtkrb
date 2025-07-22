require 'gtk3'

class GtkSplitAdapter
  def initialize(panel_manager)
    @panel_manager = panel_manager
    @gtk_panels = {}
    @main_widget = Gtk::Box.new(:vertical, 0)
    
    @panel_manager.add_observer do |event, *args|
      handle_panel_event(event, *args)
    end
  end
  
  def widget
    @main_widget
  end
  
  def create_gtk_panel(panel_id)
    editor_model = @panel_manager.get_editor(panel_id)
    return nil unless editor_model
    
    # Создаем GTK виджет для панели
    panel_widget = create_panel_widget(editor_model)
    
    # Подписываемся на изменения в модели
    editor_model.add_observer do |model, event|
      handle_editor_event(panel_id, model, event)
    end
    
    @gtk_panels[panel_id] = {
      widget: panel_widget,
      editor_model: editor_model
    }
    
    panel_widget
  end
  
  def get_gtk_panel(panel_id)
    @gtk_panels[panel_id]
  end
  
  def render_layout
    # Очищаем главный виджет
    @main_widget.children.each { |child| @main_widget.remove(child) }
    
    # Создаем виджет для текущего split_tree
    layout_widget = build_layout_widget(@panel_manager.split_tree)
    
    if layout_widget
      @main_widget.pack_start(layout_widget, expand: true, fill: true, padding: 0)
    end
  end
  
  private
  
  def handle_panel_event(event, *args)
    case event
    when :layout_changed
      render_layout
    when :panel_created
      panel_id = args[0]
      create_gtk_panel(panel_id)
    when :panel_removed
      panel_id = args[0]
      @gtk_panels.delete(panel_id)
    when :active_panel_changed
      old_id, new_id = args
      update_active_panel_styles(old_id, new_id)
    when :panels_swapped
      panel1_id, panel2_id = args
      handle_panel_swap(panel1_id, panel2_id)
    end
  end
  
  def handle_editor_event(panel_id, model, event)
    gtk_panel = @gtk_panels[panel_id]
    return unless gtk_panel
    
    case event
    when :file_loaded, :new_file
      update_panel_label(panel_id, model)
    when :content_changed
      update_panel_modified_indicator(panel_id, model)
    when :file_saved
      update_panel_label(panel_id, model)
      update_panel_modified_indicator(panel_id, model)
    end
  end
  
  def build_layout_widget(tree)
    return nil unless tree
    
    # Если это просто panel_id
    if tree.is_a?(String)
      gtk_panel = @gtk_panels[tree]
      return gtk_panel ? gtk_panel[:widget] : nil
    end
    
    # Если это split node
    if tree.is_a?(Hash) && tree[:type]
      paned = Gtk::Paned.new(tree[:type])
      
      if tree[:type] == :horizontal
        left_widget = build_layout_widget(tree[:left])
        right_widget = build_layout_widget(tree[:right])
        
        paned.pack1(left_widget, expand: true, shrink: false) if left_widget
        paned.pack2(right_widget, expand: true, shrink: false) if right_widget
        
        # Устанавливаем равномерное распределение
        set_equal_paned_position(paned, :horizontal)
      else # vertical
        top_widget = build_layout_widget(tree[:top])
        bottom_widget = build_layout_widget(tree[:bottom])
        
        paned.pack1(top_widget, expand: true, shrink: false) if top_widget
        paned.pack2(bottom_widget, expand: true, shrink: false) if bottom_widget
        
        # Устанавливаем равномерное распределение
        set_equal_paned_position(paned, :vertical)
      end
      
      return paned
    end
    
    nil
  end
  
  def set_equal_paned_position(paned, orientation)
    # Устанавливаем позицию после показа окна
    GLib::Timeout.add(50) do
      if paned.allocated_width > 0 && paned.allocated_height > 0
        if orientation == :horizontal
          position = paned.allocated_width / 2
        else
          position = paned.allocated_height / 2
        end
        paned.position = position
      end
      false # не повторять
    end
  end
  
  def create_panel_widget(editor_model)
    # Создаем простой виджет панели
    vbox = Gtk::Box.new(:vertical, 0)
    
    # Заголовок панели
    header = Gtk::Box.new(:horizontal, 5)
    header.style_context.add_class("panel-header")
    
    # Лейбл файла
    label = Gtk::Label.new(editor_model.display_name)
    label.set_alignment(0, 0.5)
    header.pack_start(label, expand: true, fill: true, padding: 5)
    
    # Кнопка закрытия
    close_btn = Gtk::Button.new
    close_btn.set_label("✕")
    close_btn.set_size_request(20, 20)
    close_btn.signal_connect("clicked") do
      panel_id = find_panel_id_by_widget(vbox)
      @panel_manager.remove_panel(panel_id) if panel_id
    end
    header.pack_end(close_btn, expand: false, fill: false, padding: 0)
    
    # Текстовое поле для содержимого
    text_view = Gtk::TextView.new
    text_view.buffer.text = editor_model.content
    text_view.signal_connect("key-release-event") do |widget, event|
      new_content = widget.buffer.text
      editor_model.set_content(new_content)
    end
    
    # Scrolled window для текста
    scrolled = Gtk::ScrolledWindow.new
    scrolled.add(text_view)
    
    vbox.pack_start(header, expand: false, fill: false, padding: 0)
    vbox.pack_start(scrolled, expand: true, fill: true, padding: 0)
    
    # Сохраняем ссылки для обновления
    vbox.instance_variable_set(:@label, label)
    vbox.instance_variable_set(:@text_view, text_view)
    
    vbox
  end
  
  def update_panel_label(panel_id, model)
    gtk_panel = @gtk_panels[panel_id]
    return unless gtk_panel
    
    widget = gtk_panel[:widget]
    label = widget.instance_variable_get(:@label)
    
    if label
      display_name = model.display_name
      display_name += " *" if model.modified?
      label.text = display_name
    end
  end
  
  def update_panel_modified_indicator(panel_id, model)
    update_panel_label(panel_id, model)
  end
  
  def update_active_panel_styles(old_id, new_id)
    # Обновляем стили активной панели
    if old_id
      gtk_panel = @gtk_panels[old_id]
      gtk_panel[:widget].style_context.remove_class("active-panel") if gtk_panel
    end
    
    if new_id
      gtk_panel = @gtk_panels[new_id]
      gtk_panel[:widget].style_context.add_class("active-panel") if gtk_panel
    end
  end
  
  def handle_panel_swap(panel1_id, panel2_id)
    # При swap'е панелей обновляем содержимое виджетов
    gtk_panel1 = @gtk_panels[panel1_id]
    gtk_panel2 = @gtk_panels[panel2_id]
    
    return unless gtk_panel1 && gtk_panel2
    
    # Обновляем содержимое текстовых полей
    update_panel_content(panel1_id)
    update_panel_content(panel2_id)
    
    # Обновляем лейблы
    update_panel_label(panel1_id, gtk_panel1[:editor_model])
    update_panel_label(panel2_id, gtk_panel2[:editor_model])
  end
  
  def update_panel_content(panel_id)
    gtk_panel = @gtk_panels[panel_id]
    return unless gtk_panel
    
    widget = gtk_panel[:widget]
    text_view = widget.instance_variable_get(:@text_view)
    
    if text_view
      text_view.buffer.text = gtk_panel[:editor_model].content
    end
  end
  
  def find_panel_id_by_widget(widget)
    @gtk_panels.each do |panel_id, gtk_panel|
      return panel_id if gtk_panel[:widget] == widget
    end
    nil
  end
end 