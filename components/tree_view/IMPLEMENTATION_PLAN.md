# Implementation Plan

## Этап 1: Создание Core Layer (1-2 дня)

### Структура
```
components/tree_view/
├── core/
│   ├── tree_controller.rb    # Контроллер команд
│   ├── tree_events.rb        # Система событий
│   ├── tree_model.rb         # Интерфейс модели
│   └── file_tree_model.rb    # Файловая модель
├── src/                      # Текущий код
└── tests/                    # Тесты
```

### Задачи
- [x] Перенести FileTreeManager → TreeModel
- [x] Создать TreeController с командами
- [x] Создать TreeEvents для событий
- [x] Написать unit-тесты для core

## Этап 2: Создание Presentation Layer (1-2 дня)

### Структура
```
components/tree_view/
├── presentation/
│   ├── abstract_renderer.rb  # Базовый рендерер
│   ├── tree_layout.rb        # Расчет макета
│   ├── render_context.rb     # Контекст рендеринга
│   └── tree_theme.rb         # Тема
```

### Задачи
- [ ] Создать AbstractRenderer с абстрактными методами
- [ ] Выделить TreeLayout для расчета позиций
- [ ] Создать RenderContext для абстракции графики
- [ ] Написать тесты с MockRenderer

## Этап 3: Создание Input Layer (1 день)

### Структура
```
components/tree_view/
├── input/
│   ├── input_controller.rb   # Обработка команд
│   ├── input_events.rb       # События ввода
│   └── navigation_engine.rb  # Навигация
```

### Задачи
- [ ] Создать InputController для обработки действий
- [ ] Создать InputEvents для событий ввода
- [ ] Добавить NavigationEngine для навигации
- [ ] Написать тесты для input layer

## Этап 4: Создание Platform Layer (1-2 дня)

### Структура
```
components/tree_view/
├── platform/
│   └── gtk3/
│       ├── gtk3_tree_widget.rb   # GTK3 виджет
│       ├── gtk3_event_adapter.rb # Адаптер событий
│       ├── gtk3_cairo_renderer.rb # Cairo рендерер
│       └── gtk3_icon_loader.rb   # Загрузка иконок
```

### Задачи
- [ ] Создать GTK3TreeWidget (минимальный GTK код)
- [ ] Создать GTK3EventAdapter для маппинга событий
- [ ] Создать GTK3CairoRenderer наследующий AbstractRenderer
- [ ] Создать GTK3IconLoader для иконок

## Этап 5: Интеграция и тестирование (1 день)

### Задачи
- [ ] Обновить FileExplorer для использования новой архитектуры
- [ ] Создать интеграционные тесты
- [ ] Убедиться что все работает как прежде
- [ ] Обновить документацию

## Этап 6: Демонстрация гибкости (опционально)

### Задачи
- [ ] Создать platform/gtk4/ с GTK4 реализацией
- [ ] Или создать platform/terminal/ с текстовым интерфейсом
- [ ] Показать что можно переключаться между фреймворками

## Ожидаемые результаты

### До рефакторинга:
```ruby
# Все смешано в одном файле
class TreeView < Gtk::DrawingArea
  # GTK зависимости повсюду
  # Логика смешана с UI
  # Тяжело тестировать
end
```

### После рефакторинга:
```ruby
# Чистая логика
controller = TreeController.new(model, state, events)

# Рендеринг
renderer = GTK3CairoRenderer.new(theme)

# Виджет
widget = GTK3TreeWidget.new(controller, renderer)

# Легко тестировать
# Легко заменить GTK3 на GTK4
```

## Преимущества

1. **Тестируемость**: 100% покрытие без GUI
2. **Гибкость**: Легко заменить фреймворк
3. **Сопровождение**: Четкое разделение ответственности
4. **Переиспользование**: Core логика работает везде
5. **Производительность**: Можно оптимизировать каждый слой

## Оценка времени

- **Минимальная реализация**: 3-4 дня
- **Полная реализация с тестами**: 5-7 дней
- **Демонстрация гибкости**: +1-2 дня

## Начать с малого

Можем начать с одного слоя и постепенно рефакторить:

1. Сначала выделить TreeController
2. Потом AbstractRenderer
3. Потом InputController
4. Наконец Platform Layer

Каждый этап даст улучшение архитектуры. 