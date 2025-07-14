# Tree View Architecture

## Предлагаемая слоистая архитектура

### 1. Core Layer (Framework-agnostic)
```
core/
├── tree_model.rb        # Модель данных и навигация
├── tree_state.rb        # Состояние компонента
├── tree_controller.rb   # Контроллер команд
└── tree_events.rb       # События и коллбеки
```

### 2. Presentation Layer (Framework-agnostic)
```
presentation/
├── abstract_renderer.rb  # Абстрактный рендерер
├── tree_theme.rb         # Тема оформления
├── tree_layout.rb        # Расчет макета
└── render_context.rb     # Контекст рендеринга
```

### 3. Input Layer (Framework-agnostic)
```
input/
├── input_controller.rb   # Обработка команд
├── input_events.rb       # События ввода
└── navigation_engine.rb  # Навигация
```

### 4. Platform Layer (Framework-specific)
```
platform/gtk3/
├── gtk3_tree_widget.rb   # GTK3 виджет
├── gtk3_event_adapter.rb # Адаптер событий GTK→Core
├── gtk3_cairo_renderer.rb # Cairo рендерер
└── gtk3_icon_loader.rb   # Загрузка иконок
```

## Преимущества

1. **Полная независимость от фреймворка**: Core/Presentation/Input слои не знают о GTK
2. **Простое переключение**: Легко заменить GTK3 на GTK4 или Qt
3. **Полное тестирование**: Можно тестировать логику без UI
4. **Чистая архитектура**: Каждый слой имеет четкую ответственность

## Интерфейсы

### Core Layer
- `TreeModel` - данные и навигация
- `TreeController` - команды (expand, select, scroll)
- `TreeEvents` - события (item_selected, item_activated)

### Presentation Layer  
- `AbstractRenderer` - рендеринг элементов
- `RenderContext` - контекст (размеры, цвета, иконки)

### Input Layer
- `InputController` - обработка команд
- `InputEvents` - события ввода (click, key, scroll)

### Platform Layer
- `PlatformWidget` - виджет для конкретного фреймворка
- `EventAdapter` - адаптер событий
- `PlatformRenderer` - рендерер для фреймворка 