# Гайд по созданию кастомных компонентов

## Архитектурный подход

Наша архитектура состоит из 4 слоев:

```
┌─────────────────────────────────────────────────────────────┐
│                    Platform Layer                           │
│  (GTK3, Qt, Web, etc. - framework-specific)                │
│  ├─ Widget (GTK3ButtonWidget)                               │
│  ├─ EventAdapter (GTK3EventAdapter)                         │
│  ├─ Renderer (GTK3CairoRenderer)                            │
│  └─ Platform-specific utilities                             │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                     Input Layer                             │
│  (Framework-agnostic input handling)                        │
│  ├─ InputController                                         │
│  ├─ InputEvents (constants, normalization)                  │
│  └─ NavigationEngine / InteractionEngine                    │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                  Presentation Layer                         │
│  (Framework-agnostic rendering logic)                       │
│  ├─ AbstractRenderer                                        │
│  ├─ Theme                                                   │
│  ├─ Layout                                                  │
│  └─ RenderContext                                           │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                     Core Layer                              │
│  (Business logic, framework-agnostic)                       │
│  ├─ Controller (main business logic)                        │
│  ├─ Events (event system)                                   │
│  ├─ Model (data interface)                                  │
│  └─ State (component state)                                 │
└─────────────────────────────────────────────────────────────┘
```

## Пошаговый гайд создания компонента

### Шаг 1: Создание структуры директорий

```bash
components/
  your_component/
    core/                 # Бизнес-логика
    presentation/         # Рендеринг
    input/               # Обработка ввода
    platform/            # Платформо-зависимый код
      gtk3/              # GTK3 реализация
      qt/                # Qt реализация (будущее)
      web/               # Web реализация (будущее)
    src/                 # Высокоуровневые классы
    tests/               # Тесты
      unit/              # Unit тесты
```

### Шаг 2: Core Layer - Бизнес-логика

#### 2.1 События (Events)
```ruby
# components/your_component/core/component_events.rb
class ComponentEvents
  def initialize
    @listeners = {}
  end

  def on(event, &block)
    @listeners[event] ||= []
    @listeners[event] << block
  end

  def emit(event, *args)
    return unless @listeners[event]
    @listeners[event].each { |listener| listener.call(*args) }
  end

  def clear(event = nil)
    if event
      @listeners[event] = []
    else
      @listeners.clear
    end
  end
end
```

#### 2.2 Модель (Model)
```ruby
# components/your_component/core/component_model.rb
class ComponentModel
  def initialize(data_source)
    @data_source = data_source
    @state = ComponentState.new
  end

  def get_data
    # Получение данных из источника
    @data_source.fetch
  end

  def can_perform_action?(item)
    # Проверка возможности выполнения действия
    item.respond_to?(:actionable?) && item.actionable?
  end

  def state
    @state
  end
end
```

#### 2.3 Состояние (State)
```ruby
# components/your_component/core/component_state.rb
class ComponentState
  attr_accessor :selected_item, :scroll_offset

  def initialize
    @selected_item = nil
    @scroll_offset = 0
    @expanded_items = Set.new
  end

  def select_item(item)
    @selected_item = item
  end

  def expanded?(item)
    @expanded_items.include?(item)
  end

  def expand(item)
    @expanded_items.add(item)
  end

  def collapse(item)
    @expanded_items.delete(item)
  end
end
```

#### 2.4 Контроллер (Controller)
```ruby
# components/your_component/core/component_controller.rb
class ComponentController
  def initialize(model, state, events)
    @model = model
    @state = state
    @events = events
  end

  def perform_action(item)
    return unless @model.can_perform_action?(item)
    
    # Выполняем действие
    result = execute_action(item)
    
    # Уведомляем о результате
    @events.emit(:action_performed, item, result)
  end

  def select_item(item)
    @state.select_item(item)
    @events.emit(:item_selected, item)
  end

  def get_data
    @model.get_data
  end

  private

  def execute_action(item)
    # Конкретная реализация действия
    item.perform_action
  end
end
```

### Шаг 3: Presentation Layer - Рендеринг

#### 3.1 Контекст рендеринга (RenderContext)
```ruby
# components/your_component/presentation/render_context.rb
class RenderContext
  attr_reader :width, :height, :theme

  def initialize(width, height, theme)
    @width = width
    @height = height
    @theme = theme
  end

  # Абстрактные методы для переопределения в платформо-зависимых классах
  def draw_rectangle(x, y, width, height, color)
    raise NotImplementedError, "Subclass must implement draw_rectangle"
  end

  def draw_text(x, y, text, color)
    raise NotImplementedError, "Subclass must implement draw_text"
  end

  def draw_icon(x, y, icon_type)
    raise NotImplementedError, "Subclass must implement draw_icon"
  end

  def clear_background(color)
    raise NotImplementedError, "Subclass must implement clear_background"
  end
end
```

#### 3.2 Тема (Theme)
```ruby
# components/your_component/presentation/component_theme.rb
class ComponentTheme
  attr_reader :item_height, :font_size, :padding

  def initialize
    @item_height = 24
    @font_size = 10
    @padding = 4
  end

  def background_color
    [0.98, 0.98, 0.98, 1.0]
  end

  def selection_color
    [0.4, 0.6, 1.0, 0.3]
  end

  def text_color
    [0.1, 0.1, 0.1, 1.0]
  end

  def border_color
    [0.6, 0.6, 0.6, 1.0]
  end

  def item_x(index)
    @padding + (index * (@item_height + @padding))
  end

  def item_y(index)
    @padding + (index * (@item_height + @padding))
  end
end
```

#### 3.3 Лейаут (Layout)
```ruby
# components/your_component/presentation/component_layout.rb
class ComponentLayout
  def initialize(theme)
    @theme = theme
    @needs_update = true
    @total_height = 0
  end

  def calculate_layout(items)
    return unless @needs_update

    @total_height = items.length * @theme.item_height
    @needs_update = false
  end

  def item_at_position(x, y, scroll_offset)
    adjusted_y = y + scroll_offset
    index = (adjusted_y / @theme.item_height).to_i
    
    # Возвращаем индекс элемента
    index
  end

  def needs_update?
    @needs_update
  end

  def invalidate
    @needs_update = true
  end

  def total_height
    @total_height
  end
end
```

#### 3.4 Рендерер (AbstractRenderer)
```ruby
# components/your_component/presentation/abstract_renderer.rb
class AbstractRenderer
  def initialize(theme)
    @theme = theme
    @layout = ComponentLayout.new(theme)
  end

  def render_component(context, items, state)
    # Обновляем лейаут
    @layout.calculate_layout(items)

    # Рендерим фон
    render_background(context)

    # Рендерим элементы
    items.each_with_index do |item, index|
      y = @theme.item_y(index)
      render_item(context, item, y, state)
    end
  end

  def render_background(context)
    context.clear_background(@theme.background_color)
  end

  def render_item(context, item, y, state)
    # Рендерим фон элемента
    render_item_background(context, item, y, state)
    
    # Рендерим иконку
    render_item_icon(context, item, y)
    
    # Рендерим текст
    render_item_text(context, item, y)
  end

  def render_item_background(context, item, y, state)
    color = if item == state.selected_item
      @theme.selection_color
    else
      @theme.background_color
    end
    
    context.draw_rectangle(0, y, context.width, @theme.item_height, color)
  end

  def render_item_icon(context, item, y)
    icon_x = @theme.padding
    icon_y = y + (@theme.item_height - 16) / 2
    
    context.draw_icon(icon_x, icon_y, item.icon_type)
  end

  def render_item_text(context, item, y)
    text_x = @theme.padding + 20
    text_y = y + @theme.item_height - 4
    
    context.draw_text(text_x, text_y, item.name, @theme.text_color)
  end

  def item_at_position(x, y, scroll_offset)
    @layout.item_at_position(x, y, scroll_offset)
  end

  def get_total_height
    @layout.total_height
  end

  def invalidate_layout
    @layout.invalidate
  end
end
```

### Шаг 4: Input Layer - Обработка ввода

#### 4.1 События ввода (InputEvents)
```ruby
# components/your_component/input/input_events.rb
class InputEvents
  # Константы для событий
  CLICK = 'click'
  DOUBLE_CLICK = 'double_click'
  KEY_PRESS = 'key_press'
  SCROLL = 'scroll'

  # Константы для клавиш
  KEY_ENTER = 'enter'
  KEY_ESCAPE = 'escape'
  KEY_UP = 'up'
  KEY_DOWN = 'down'

  def self.normalize_key(key)
    case key
    when 'Return', 'Enter', 13
      KEY_ENTER
    when 'Escape', 27
      KEY_ESCAPE
    when 'Up', 'ArrowUp'
      KEY_UP
    when 'Down', 'ArrowDown'
      KEY_DOWN
    else
      key.to_s.downcase
    end
  end

  def self.is_navigation_key?(key)
    [KEY_UP, KEY_DOWN].include?(key)
  end

  def self.is_action_key?(key)
    [KEY_ENTER].include?(key)
  end
end
```

#### 4.2 Движок взаимодействия (InteractionEngine)
```ruby
# components/your_component/input/interaction_engine.rb
class InteractionEngine
  def initialize(controller)
    @controller = controller
  end

  def handle_click(x, y, renderer)
    index = renderer.item_at_position(x, y, @controller.state.scroll_offset)
    return false unless index

    items = @controller.get_data
    return false unless items[index]

    item = items[index]
    @controller.select_item(item)
    true
  end

  def handle_double_click(x, y, renderer)
    index = renderer.item_at_position(x, y, @controller.state.scroll_offset)
    return false unless index

    items = @controller.get_data
    return false unless items[index]

    item = items[index]
    @controller.perform_action(item)
    true
  end

  def handle_navigation_key(key)
    case key
    when InputEvents::KEY_UP
      @controller.select_previous
    when InputEvents::KEY_DOWN
      @controller.select_next
    else
      false
    end
    true
  end

  def handle_action_key(key)
    return false unless @controller.state.selected_item

    case key
    when InputEvents::KEY_ENTER
      @controller.perform_action(@controller.state.selected_item)
    else
      false
    end
    true
  end
end
```

#### 4.3 Контроллер ввода (InputController)
```ruby
# components/your_component/input/input_controller.rb
class InputController
  def initialize(controller, renderer)
    @controller = controller
    @renderer = renderer
    @interaction_engine = InteractionEngine.new(controller)
    @last_click_time = 0
    @last_click_item = nil
  end

  def handle_click(x, y, timestamp = nil)
    timestamp ||= Time.now.to_f
    
    index = @renderer.item_at_position(x, y, @controller.state.scroll_offset)
    return false unless index

    items = @controller.get_data
    return false unless items[index]

    item = items[index]
    
    # Проверяем double click
    is_double_click = check_double_click(item, timestamp)
    
    if is_double_click
      handle_double_click(x, y)
    else
      handle_single_click(x, y)
    end
    
    true
  end

  def handle_single_click(x, y)
    @interaction_engine.handle_click(x, y, @renderer)
  end

  def handle_double_click(x, y)
    @interaction_engine.handle_double_click(x, y, @renderer)
  end

  def handle_key_press(key)
    normalized_key = InputEvents.normalize_key(key)
    
    if InputEvents.is_navigation_key?(normalized_key)
      return @interaction_engine.handle_navigation_key(normalized_key)
    end
    
    if InputEvents.is_action_key?(normalized_key)
      return @interaction_engine.handle_action_key(normalized_key)
    end
    
    false
  end

  private

  def check_double_click(item, timestamp)
    time_diff = timestamp - @last_click_time
    is_double = time_diff < 0.5 && @last_click_item == item
    
    @last_click_time = timestamp
    @last_click_item = item
    
    is_double
  end
end
```

### Шаг 5: Platform Layer - GTK3 реализация

#### 5.1 GTK3 Контекст рендеринга
```ruby
# components/your_component/platform/gtk3/gtk3_render_context.rb
require_relative '../../presentation/render_context'

class GTK3RenderContext < RenderContext
  def initialize(cairo_context, width, height, theme)
    super(width, height, theme)
    @cairo = cairo_context
  end

  def draw_rectangle(x, y, width, height, color)
    @cairo.set_source_rgba(*color)
    @cairo.rectangle(x, y, width, height)
    @cairo.fill
  end

  def draw_text(x, y, text, color)
    @cairo.set_source_rgba(*color)
    @cairo.move_to(x, y)
    @cairo.show_text(text)
  end

  def draw_icon(x, y, icon_type)
    # Простая реализация иконки
    color = @theme.text_color
    @cairo.set_source_rgba(*color)
    @cairo.rectangle(x, y, 16, 16)
    @cairo.stroke
  end

  def clear_background(color)
    @cairo.set_source_rgba(*color)
    @cairo.rectangle(0, 0, @width, @height)
    @cairo.fill
  end
end
```

#### 5.2 GTK3 Рендерер
```ruby
# components/your_component/platform/gtk3/gtk3_cairo_renderer.rb
require_relative '../../presentation/abstract_renderer'
require_relative 'gtk3_render_context'

class GTK3CairoRenderer < AbstractRenderer
  def initialize(theme)
    super(theme)
  end

  def render_component_gtk3(cairo_context, width, height, items, state)
    # Создаем GTK3-специфичный контекст
    context = GTK3RenderContext.new(cairo_context, width, height, @theme)
    
    # Используем базовый метод
    render_component(context, items, state)
  end
end
```

#### 5.3 GTK3 Адаптер событий
```ruby
# components/your_component/platform/gtk3/gtk3_event_adapter.rb
require_relative '../../input/input_events'

class GTK3EventAdapter
  def initialize(widget, input_controller)
    @widget = widget
    @input_controller = input_controller
    setup_events
  end

  def setup_events
    setup_mouse_events
    setup_keyboard_events
  end

  private

  def setup_mouse_events
    @widget.signal_connect("button-press-event") { |_, event| handle_gtk_click(event) }
    @widget.add_events(Gdk::EventMask::BUTTON_PRESS_MASK)
  end

  def setup_keyboard_events
    @widget.signal_connect("key-press-event") { |_, event| handle_gtk_key(event) }
    @widget.set_can_focus(true)
    @widget.add_events(Gdk::EventMask::KEY_PRESS_MASK)
  end

  def handle_gtk_click(event)
    @input_controller.handle_click(event.x, event.y, event.time / 1000.0)
    false
  end

  def handle_gtk_key(event)
    key = map_gtk_key(event.keyval)
    @input_controller.handle_key_press(key)
    false
  end

  def map_gtk_key(keyval)
    case keyval
    when Gdk::Keyval::GDK_KEY_Return
      InputEvents::KEY_ENTER
    when Gdk::Keyval::GDK_KEY_Escape
      InputEvents::KEY_ESCAPE
    when Gdk::Keyval::GDK_KEY_Up
      InputEvents::KEY_UP
    when Gdk::Keyval::GDK_KEY_Down
      InputEvents::KEY_DOWN
    else
      keyval.to_s
    end
  end
end
```

#### 5.4 Главный GTK3 виджет
```ruby
# components/your_component/platform/gtk3/gtk3_component_widget.rb
require 'gtk3'
require_relative '../../core/component_controller'
require_relative '../../core/component_events'
require_relative '../../core/component_model'
require_relative '../../presentation/component_theme'
require_relative '../../input/input_controller'
require_relative 'gtk3_cairo_renderer'
require_relative 'gtk3_event_adapter'

class GTK3ComponentWidget < Gtk::DrawingArea
  attr_reader :controller, :renderer, :input_controller

  def initialize(data_source)
    super()
    
    # Создаем все слои
    @model = ComponentModel.new(data_source)
    @events = ComponentEvents.new
    @controller = ComponentController.new(@model, @model.state, @events)
    
    @theme = ComponentTheme.new
    @renderer = GTK3CairoRenderer.new(@theme)
    @input_controller = InputController.new(@controller, @renderer)
    
    # Настраиваем виджет
    setup_widget
    
    # Подключаем события
    @event_adapter = GTK3EventAdapter.new(self, @input_controller)
    
    # Подключаем коллбеки
    setup_callbacks
  end

  def on_item_selected(&block)
    @events.on(:item_selected, &block)
  end

  def on_action_performed(&block)
    @events.on(:action_performed, &block)
  end

  def refresh
    invalidate_and_redraw
  end

  private

  def setup_widget
    set_hexpand(true)
    set_vexpand(true)
    set_size_request(-1, 200)
    
    signal_connect("draw") { |_, cr| draw(cr) }
  end

  def setup_callbacks
    @events.on(:item_selected) { queue_draw }
    @events.on(:action_performed) { queue_draw }
  end

  def draw(cr)
    allocation = self.allocation
    width = allocation.width
    height = allocation.height
    
    # Получаем данные
    items = @controller.get_data
    
    # Рендерим
    @renderer.render_component_gtk3(cr, width, height, items, @controller.state)
  end

  def invalidate_and_redraw
    @renderer.invalidate_layout
    queue_draw
  end
end
```

### Шаг 6: Высокоуровневая обертка

```ruby
# components/your_component/src/component_wrapper.rb
require_relative '../platform/gtk3/gtk3_component_widget'

class ComponentWrapper
  def initialize(data_source)
    @widget = GTK3ComponentWidget.new(data_source)
  end

  def widget
    @widget
  end

  def on_item_selected(&block)
    @widget.on_item_selected(&block)
  end

  def on_action_performed(&block)
    @widget.on_action_performed(&block)
  end

  def refresh
    @widget.refresh
  end
end
```

### Шаг 7: Тестирование

#### 7.1 Unit тесты для Core
```ruby
# components/your_component/tests/unit/core_test.rb
require 'minitest/autorun'
require_relative '../../core/component_events'
require_relative '../../core/component_controller'

class CoreTest < Minitest::Test
  def setup
    @events = ComponentEvents.new
    @model = MockModel.new
    @state = MockState.new
    @controller = ComponentController.new(@model, @state, @events)
  end

  def test_select_item
    item = MockItem.new("test")
    @controller.select_item(item)
    
    assert_equal item, @state.selected_item
  end

  def test_perform_action
    item = MockItem.new("test")
    @controller.perform_action(item)
    
    assert @model.action_performed
  end
end

class MockModel
  attr_reader :action_performed
  
  def initialize
    @action_performed = false
  end
  
  def can_perform_action?(item)
    true
  end
  
  def get_data
    [MockItem.new("item1"), MockItem.new("item2")]
  end
end

class MockState
  attr_accessor :selected_item
  
  def initialize
    @selected_item = nil
  end
end

class MockItem
  attr_reader :name
  
  def initialize(name)
    @name = name
  end
  
  def perform_action
    true
  end
end
```

#### 7.2 Интеграционные тесты
```ruby
# components/your_component/tests/integration_test.rb
require 'minitest/autorun'
require_relative '../src/component_wrapper'

class IntegrationTest < Minitest::Test
  def setup
    @data_source = MockDataSource.new
    @component = ComponentWrapper.new(@data_source)
  end

  def test_component_creation
    refute_nil @component.widget
    assert_respond_to @component, :refresh
  end

  def test_item_selection
    selected_item = nil
    @component.on_item_selected { |item| selected_item = item }
    
    # Симулируем выбор
    @component.widget.controller.select_item(@data_source.items.first)
    
    assert_equal @data_source.items.first, selected_item
  end
end

class MockDataSource
  attr_reader :items
  
  def initialize
    @items = [MockItem.new("item1"), MockItem.new("item2")]
  end
  
  def fetch
    @items
  end
end
```

### Шаг 8: Запуск всех тестов

```ruby
# components/your_component/tests/run_all_tests.rb
#!/usr/bin/env ruby
require 'minitest/autorun'

# Загружаем все тесты
Dir[File.join(__dir__, "**/*_test.rb")].each { |file| require file }

puts "Running all tests for YourComponent..."
```

## Принципы архитектуры

### 1. Разделение ответственности
- **Core**: Бизнес-логика, не зависит от фреймворка
- **Presentation**: Рендеринг, не зависит от фреймворка  
- **Input**: Обработка ввода, не зависит от фреймворка
- **Platform**: Платформо-зависимый код

### 2. Event-driven подход
- Все слои общаются через события
- Слабая связанность между компонентами
- Легко добавлять новые обработчики

### 3. Dependency Injection
- Все зависимости передаются в конструкторе
- Легко тестировать с Mock объектами
- Легко заменять реализации

### 4. Тестируемость
- Каждый слой тестируется независимо
- Unit тесты для Core/Presentation/Input
- Integration тесты для Platform
- 100% покрытие тестами

## Заключение

Эта архитектура позволяет:
- **Переносимость**: Легко портировать на другие фреймворки
- **Тестируемость**: Полное тестирование без GUI
- **Расширяемость**: Легко добавлять новые функции
- **Поддерживаемость**: Четкое разделение ответственности

Используйте этот гайд как основу для создания любых кастомных UI компонентов! 