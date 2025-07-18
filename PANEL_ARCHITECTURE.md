# Архитектура панелей GTKRB

## Обзор

Новая архитектура панелей в GTKRB обеспечивает гибкую систему для поддержки разных типов контента в панелях: редактор кода, терминал, файловый менеджер и другие.

## Основные компоненты

### 1. BasePanel (базовый класс)

Абстрактный базовый класс для всех панелей:

```ruby
class BasePanel
  attr_reader :panel_id, :panel_type
  
  # Абстрактные методы
  def setup_ui        # Настройка UI
  def get_title       # Заголовок панели
  def can_close?      # Можно ли закрыть
  def has_unsaved_changes? # Есть ли несохраненные изменения
  def save            # Сохранить
  def focus           # Установить фокус
end
```

### 2. Типы панелей

#### EditorPanel
- Редактор кода с подсветкой синтаксиса
- История файлов
- Автосохранение
- Поддержка разных языков

#### TerminalPanel  
- Встроенный терминал VTE
- Настройка рабочей директории
- Перезапуск терминала
- Темная тема

#### FileManagerPanel
- Файловый менеджер с иконками
- Контекстное меню
- Создание файлов/папок
- Навигация по директориям

### 3. PanelFactory

Фабрика для создания панелей:

```ruby
# Создание панели по типу
panel = PanelFactory.create_panel(:editor)
panel = PanelFactory.create_panel(:terminal, working_dir: "/path")
panel = PanelFactory.create_panel(:file_manager, root_dir: "/path")

# Удобные методы
panel = PanelFactory.create_editor_with_file("file.rb")
panel = PanelFactory.create_terminal_in_dir("/path")
panel = PanelFactory.create_panel_for_file("file.rb")
```

### 4. PanelManager

Менеджер панелей:

```ruby
manager = PanelManager.new(container)

# Создание панелей
manager.create_editor_panel
manager.create_terminal_panel
manager.create_file_manager_panel

# Управление
manager.split_horizontal
manager.split_vertical
manager.close_panel(panel)
manager.enter_grid_mode
```

## Архитектура классов

```
BasePanel (abstract)
├── EditorPanel
├── TerminalPanel
├── FileManagerPanel
└── ... (другие типы)

PanelFactory
├── create_panel(type, options)
├── create_editor_with_file(path)
├── create_terminal_in_dir(dir)
└── create_panel_for_file(path)

PanelManager
├── @panels: Array<BasePanel>
├── @active_panel: BasePanel
├── @container: SplitContainer
└── callbacks system
```

## Система событий

Каждая панель поддерживает callbacks:

```ruby
panel.on_focus { |panel| ... }
panel.on_modified { ... }
panel.on_close { |panel| ... }
panel.on_split_horizontal { |panel| ... }
panel.on_split_vertical { |panel| ... }
panel.on_save { |panel| ... }
panel.on_history { |panel| ... }
```

## Интерфейс кнопок

Каждая панель имеет заголовок с кнопками:

### EditorPanel
- **⊞** Focus - фокус на панели
- **❙** Split Vertical - разделить вертикально
- **═** Split Horizontal - разделить горизонтально
- **⏷** File History - история файлов
- **💾** Save - сохранить
- **✗** Close - закрыть

### TerminalPanel
- **⊞** Focus - фокус на панели
- **❙** Split Vertical - разделить вертикально
- **═** Split Horizontal - разделить горизонтально
- **🔄** Restart - перезапустить терминал
- **📝** New Editor - создать редактор
- **✗** Close - закрыть

### FileManagerPanel
- **⊞** Focus - фокус на панели
- **❙** Split Vertical - разделить вертикально
- **═** Split Horizontal - разделить горизонтально
- **🔄** Refresh - обновить список файлов
- **📝** New Editor - создать редактор
- **✗** Close - закрыть

## Расширение архитектуры

### Добавление нового типа панели

1. Создать класс, наследующий от `BasePanel`
2. Реализовать абстрактные методы
3. Добавить тип в `PanelFactory`
4. Добавить специфичные callbacks в `PanelManager`

Пример:

```ruby
class ImageViewerPanel < BasePanel
  def initialize(image_path)
    super(:image_viewer)
    @image_path = image_path
  end

  def setup_ui
    # Настройка UI для просмотра изображений
  end

  def get_title
    "Image: #{File.basename(@image_path)}"
  end
end
```

### Добавление в PanelFactory

```ruby
def self.create_panel(type, options = {})
  case type
  when :image_viewer
    ImageViewerPanel.new(options[:image_path])
  # ... другие типы
  end
end
```

## Интеграция с SplitContainer

Панели интегрируются с системой разделения:

```ruby
@container.split_horizontal(panel1, panel2)
@container.split_vertical(panel1, panel2)
@container.set_grid_layout(panels)
@container.replace_panel(old_panel, new_panel)
```

## Преимущества новой архитектуры

1. **Гибкость** - легко добавлять новые типы панелей
2. **Модульность** - каждый тип панели независим
3. **Единообразие** - общий интерфейс для всех панелей
4. **Расширяемость** - простое добавление функций
5. **Переиспользование** - общие компоненты в базовом классе

## Миграция с старой архитектуры

Старая `EditorPane` заменена на:
- `EditorPanel` - для редактора
- `TerminalPanel` - для терминала
- `BasePanel` - базовый функционал

Старый `EditorManager` заменен на:
- `PanelManager` - управление панелями
- `PanelFactory` - создание панелей

Сохранена обратная совместимость API для основных операций. 