# Компоненты UI

Этот каталог содержит кастомные UI компоненты, построенные на 4-слойной архитектуре.

## Существующие компоненты

- **`tree_view/`** - Компонент древовидного представления файлов
  - Поддерживает navigation, expand/collapse, selection
  - Полностью тестируемый (90/90 тестов)
  - Готов к переносу на другие фреймворки

## Создание нового компонента

📖 **Полный гайд**: [`CUSTOM_COMPONENT_GUIDE.md`](CUSTOM_COMPONENT_GUIDE.md)

### Быстрый старт

1. **Создайте структуру**:
```bash
components/my_component/
├── core/           # Бизнес-логика
├── presentation/   # Рендеринг
├── input/          # Обработка ввода
├── platform/       # Платформо-зависимый код
│   └── gtk3/
├── src/            # Высокоуровневые классы
└── tests/          # Тесты
```

2. **Используйте архитектуру**:
```
Platform Layer (GTK3/Qt/Web)
      ↓
Input Layer (events, navigation)
      ↓
Presentation Layer (rendering, themes)
      ↓
Core Layer (business logic)
```

3. **Принципы**:
   - **Event-driven**: Слои общаются через события
   - **Framework-agnostic**: Core/Presentation/Input не зависят от GTK
   - **Testable**: Каждый слой тестируется независимо
   - **Portable**: Легко портировать между фреймворками

### Пример использования

```ruby
# Создание компонента
widget = GTK3MyComponentWidget.new(data_source)

# Подключение событий
widget.on_item_selected { |item| puts "Selected: #{item.name}" }

# Интеграция в UI
container.add(widget)
```

## Архитектурные преимущества

✅ **Переносимость**: GTK3 → GTK4/Qt за счет замены только Platform Layer  
✅ **Тестируемость**: 100% покрытие тестами без GUI  
✅ **Расширяемость**: Легко добавлять новые функции  
✅ **Поддерживаемость**: Четкое разделение ответственности  

## Тестирование

```bash
# Тестирование tree_view
cd components/tree_view/tests && ruby integration_final_test.rb

# Шаблон для новых компонентов
cd components/my_component/tests && ruby run_all_tests.rb
``` 