# Рефакторинг FileTreeView

## Проблемы исходного кода

### Нарушение принципов SOLID:
- **SRP**: `SimpleCustomTree` делал слишком много (отрисовка, события, файловая система)
- **OCP**: Сложно расширять без изменения существующего кода
- **DIP**: Жесткая связанность с файловой системой

### Дублирование кода:
- Два похожих класса: `SimpleCustomTree` и `CustomTreeWidget`
- Повторяющаяся логика отрисовки и обработки событий

## Решение

### 1. Разделение ответственностей

#### `TreeViewTheme` - Конфигурация внешнего вида
```ruby
class TreeViewTheme
  ICON_FOLDER = GdkPixbuf::Pixbuf.new(file: "icons/folder.png", width: 14, height: 14)
  COLORS = { background: [0xfdf6e3, 0.97], selection: [0xb58900, 0.15] }
  # ...
end
```

#### `TreeItem` - Модель данных
```ruby
class TreeItem
  attr_accessor :name, :path, :type, :level, :children, :expanded
  def directory?; [:directory, :current].include?(@type); end
  # ...
end
```

#### `TreeItemRenderer` - Отрисовка элементов
```ruby
class TreeItemRenderer
  def render(cr, item, x, y, width, height, selected, hovered)
    draw_background(cr, x, y, width, height, selected, hovered)
    draw_icon(cr, item, x, y)
    draw_expander(cr, item, x, y) if item.directory?
    draw_text(cr, item, x, y)
  end
end
```

#### `TreeEventController` - Обработка событий
```ruby
class TreeEventController
  def setup_mouse_events
    click = Gtk::GestureClick.new
    click.signal_connect("pressed") { |_, n_press, x, y| handle_click(n_press, x, y) }
    # ...
  end
end
```

### 2. Стратегия провайдеров данных

#### Интерфейс `TreeDataProvider`
```ruby
class TreeDataProvider
  def get_items(path); raise NotImplementedError; end
  def get_children(item); raise NotImplementedError; end
  def can_expand?(item); raise NotImplementedError; end
  def get_icon(item); raise NotImplementedError; end
  def get_text(item); raise NotImplementedError; end
end
```

#### Реализации:
- `FileSystemDataProvider` - для файловой системы
- `GitDataProvider` - для Git репозиториев

### 3. Основной компонент `FileTreeView`

```ruby
class FileTreeView < Gtk::ScrolledWindow
  def initialize(data_provider = nil)
    @data_provider = data_provider || FileSystemDataProvider.new
    @renderer = TreeItemRenderer.new
    @event_controller = TreeEventController.new(self)
  end
  
  def set_data_provider(provider)
    @data_provider = provider
    refresh
  end
end
```

## Преимущества рефакторинга

### 1. **SOLID принципы**:
- ✅ **SRP**: Каждый класс имеет одну ответственность
- ✅ **OCP**: Легко расширять через провайдеры данных
- ✅ **LSP**: Провайдеры взаимозаменяемы
- ✅ **ISP**: Интерфейсы специфичны
- ✅ **DIP**: Зависимость от абстракций

### 2. **DRY**: Устранено дублирование кода

### 3. **KISS**: Простые, понятные классы

### 4. **Расширяемость**:
- Новые типы данных через провайдеры
- Кастомные темы через `TreeViewTheme`
- Дополнительные события через сигналы

## Использование

### Базовое использование:
```ruby
tree = FileTreeView.new
tree.load_directory(Dir.pwd)
tree.signal_connect("file-selected") { |_, path| puts "Selected: #{path}" }
```

### С кастомным провайдером:
```ruby
git_provider = GitDataProvider.new(Dir.pwd)
tree = FileTreeView.new(git_provider)
```

### Переключение провайдеров:
```ruby
tree.set_data_provider(FileSystemDataProvider.new)
```

## Миграция

Старый код:
```ruby
@tree = SimpleCustomTree.new
@tree.define_singleton_method(:open_file) do |path|
  block.call(path)
end
```

Новый код:
```ruby
@tree = FileTreeView.new
@tree.signal_connect("file-selected") do |_, path|
  block.call(path)
end
```

## Тестирование

Запуск тестового приложения:
```bash
ruby test/file_tree_view_test.rb
```

## Дальнейшее развитие

1. **Дополнительные провайдеры**:
   - FTP/SFTP провайдер
   - База данных провайдер
   - API провайдер

2. **Расширенные темы**:
   - Темная тема
   - Кастомные иконки
   - Анимации

3. **Дополнительные функции**:
   - Drag & Drop
   - Контекстные меню
   - Поиск и фильтрация
   - Сортировка 