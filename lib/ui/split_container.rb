require 'gtk3'

class SplitContainer
  def initialize
    @root = nil
    @panes = {}
    @main_widget = Gtk::Box.new(:vertical, 0)
  end

  def widget
    @main_widget
  end

  def set_root(pane)
    @root = pane
    @panes[pane] = { widget: pane.widget, parent: nil }
    @main_widget.pack_start(pane.widget, expand: true, fill: true, padding: 0)
  end

  def split_horizontal(existing_pane, new_pane)
    split_pane(existing_pane, new_pane, :horizontal)
  end

  def split_vertical(existing_pane, new_pane)
    split_pane(existing_pane, new_pane, :vertical)
  end

  def remove_pane(pane)
    pane_info = @panes[pane]
    return unless pane_info

    parent = pane_info[:parent]
    
    if parent
      # Найдем sibling панель
      sibling = find_sibling(parent, pane)
      if sibling
        # Удаляем целевую панель из paned
        parent.remove(pane_info[:widget])
        # Заменяем paned на sibling панель
        replace_paned_with_child(parent, sibling)
      end
    else
      # Это root панель
      if @panes.length > 1
        @main_widget.remove(pane.widget)
        # Находим любую другую панель и делаем её новой root
        other_pane = @panes.keys.find { |p| p != pane }
        if other_pane
          @root = other_pane
          @panes[other_pane][:parent] = nil
        end
      else
        return # Не удаляем последнюю панель
      end
    end
    
    @panes.delete(pane)
  end

  private

  def split_pane(existing_pane, new_pane, orientation)
    existing_info = @panes[existing_pane]
    return unless existing_info

    # Создаем новый Paned
    paned = Gtk::Paned.new(orientation)
    
    # Заменяем существующий виджет новым Paned контейнером
    parent = existing_info[:parent]
    existing_widget = existing_info[:widget]
    
    if parent
      # Панель уже внутри Paned контейнера
      if parent.child1 == existing_widget
        parent.remove(existing_widget)
        parent.pack1(paned, resize: true, shrink: true)
      elsif parent.child2 == existing_widget
        parent.remove(existing_widget)
        parent.pack2(paned, resize: true, shrink: true)
      end
    else
      # Панель в корне
      @main_widget.remove(existing_widget)
      @main_widget.pack_start(paned, expand: true, fill: true, padding: 0)
    end
    
    # Помещаем панели в новый Paned
    paned.pack1(existing_widget, resize: true, shrink: true)
    paned.pack2(new_pane.widget, resize: true, shrink: true)
    
    # Показываем все виджеты
    paned.show_all
    
    # Устанавливаем позицию для деления пополам после отрисовки
    GLib::Idle.add do
      allocation = paned.allocation
      half_size = orientation == :horizontal ? allocation.width / 2 : allocation.height / 2
      paned.set_position(half_size) if half_size > 0
      false
    end
    
    # Обновляем информацию о панелях
    @panes[existing_pane][:parent] = paned
    @panes[new_pane] = { widget: new_pane.widget, parent: paned }
    
    # Если это была root панель, обновляем root
    if @root == existing_pane
      @root = nil  # Теперь root - это paned контейнер
    end
  end

  def find_sibling(paned, target_pane)
    target_widget = @panes[target_pane][:widget]
    
    # Получаем оба дочерних виджета
    child1 = paned.child1
    child2 = paned.child2
    
    # Находим sibling
    if child1 == target_widget
      return find_pane_by_widget(child2)
    elsif child2 == target_widget
      return find_pane_by_widget(child1)
    end
    
    nil
  end

  def find_pane_by_widget(widget)
    @panes.each do |pane, info|
      return pane if info[:widget] == widget
    end
    nil
  end

  def replace_paned_with_child(paned, child_pane)
    child_info = @panes[child_pane]
    child_widget = child_info[:widget]
    
    # Найдем родителя Paned
    paned_parent = paned.parent
    
    # Запомним позицию paned в родителе перед удалением
    is_child1 = false
    if paned_parent && paned_parent.is_a?(Gtk::Paned)
      is_child1 = (paned_parent.child1 == paned)
    end
    
    # Сначала удаляем child_widget из paned
    paned.remove(child_widget)
    
    if paned_parent
      # Удаляем Paned из родителя
      paned_parent.remove(paned)
      
      # Добавляем дочерний виджет вместо Paned
      if paned_parent.is_a?(Gtk::Paned)
        if is_child1
          paned_parent.pack1(child_widget, resize: true, shrink: true)
        else
          paned_parent.pack2(child_widget, resize: true, shrink: true)
        end
        @panes[child_pane] = { widget: child_widget, parent: paned_parent }
      else
        paned_parent.pack_start(child_widget, expand: true, fill: true, padding: 0)
        @panes[child_pane] = { widget: child_widget, parent: nil }
      end
    else
      # Paned был в корне
      @main_widget.remove(paned)
      @main_widget.pack_start(child_widget, expand: true, fill: true, padding: 0)
      @panes[child_pane] = { widget: child_widget, parent: nil }
      @root = child_pane
    end
  end
end 