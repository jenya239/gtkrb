# Реорганизация структуры проекта

## 🎯 Цель
- Переместить tree view компонент и тесты в отдельную папку
- Вспомогательные файлы в отдельную папку
- Исправить баги с разворачиванием и выделением

## 📁 Новая структура

### До реорганизации
```
lib/
├── core/
│   ├── file_tree_*.rb
│   └── language_manager.rb
└── ui/
    └── widgets/
        ├── file_tree_data_source.rb
        ├── file_tree_adapter.rb
        └── tree_view.rb

test/
├── file_tree_manager_test.rb
├── integration_test.rb
├── simple_test.rb
└── run_all_tests.rb
```

### После реорганизации
```
components/
└── tree_view/
    ├── src/
    │   ├── file_tree_item.rb
    │   ├── file_tree_state.rb
    │   ├── file_tree_manager.rb
    │   ├── file_tree_adapter.rb
    │   └── tree_view.rb
    └── tests/
        ├── file_tree_manager_test.rb
        ├── integration_test.rb
        └── simple_test.rb

utils/
├── language_manager.rb
├── run_all_tests.rb
└── REFACTORING_REPORT.md

lib/ui/widgets/
└── minimap.rb
```

## 🐛 Исправленные баги

### 1. Разворачивание не inplace
**Проблема**: Элементы появлялись в конце списка вместо места родителя
**Решение**: Переписал `get_flat_tree()` с рекурсивным подходом вместо queue

```ruby
# Было (queue подход):
def get_flat_tree
  items = []
  queue = get_root_items.map { |item| [item, 0] }
  
  while queue.any?
    item, level = queue.shift
    items << [item, level]
    
    if @state.expanded?(item) && item.can_expand?
      children = get_children(item)
      children.each { |child| queue << [child, level + 1] }
    end
  end
  
  items
end

# Стало (рекурсивный подход):
def get_flat_tree
  items = []
  root_items = get_root_items
  
  root_items.each do |item|
    add_item_to_flat_tree(items, item, 0)
  end
  
  items
end

def add_item_to_flat_tree(items, item, level)
  items << [item, level]
  
  if @state.expanded?(item) && item.can_expand?
    children = get_children(item)
    children.each do |child|
      add_item_to_flat_tree(items, child, level + 1)
    end
  end
end
```

### 2. Странное выделение первого элемента
**Проблема**: Первый элемент автоматически выделялся при обновлении
**Решение**: Убрал автоматическое выделение в `refresh()`

```ruby
# Было:
def refresh
  @state.selected_item = nil
  @state.hovered_item = nil
  @layout_cache.invalidate
  queue_draw
end

# Стало:
def refresh
  @state.selected_item = nil  # Убираем автоматическое выделение
  @state.hovered_item = nil
  @layout_cache.invalidate
  queue_draw
end
```

### 3. Улучшенный рендеринг
- Исправил позиционирование иконок и текста
- Улучшил отображение expander (плюс/минус)
- Исправил проблемы с отступами

```ruby
# Улучшенное позиционирование
icon_x = x + indent + 2  # было +1
icon_y = y + 2          # было +1
text_x = icon_x + 18    # было +15
exp_x = icon_x + 16     # было +18

# Улучшенный expander
if data_source.state.expanded?(item)
  # Минус для развернутого
  cr.move_to(exp_x - 3, exp_y)
  cr.line_to(exp_x + 3, exp_y)
else
  # Плюс для свернутого
  cr.move_to(exp_x, exp_y - 3)
  cr.line_to(exp_x, exp_y + 3)
  cr.stroke
  cr.move_to(exp_x - 3, exp_y)
  cr.line_to(exp_x + 3, exp_y)
end
```

## ✅ Преимущества новой структуры

### Модульность
- Tree view компонент полностью изолирован
- Легко переиспользовать в других проектах
- Четкое разделение ответственности

### Тестирование
- Тесты рядом с кодом компонента
- Легко запускать только тесты компонента
- Изолированное тестирование логики

### Поддержка
- Вспомогательные файлы в отдельной папке
- Легко найти и обновить утилиты
- Чистая структура проекта

## 🧪 Тестирование

Все тесты проходят успешно:
```
✅ Пройдено: 3
❌ Провалено: 0
📈 Всего: 3
🎉 Все тесты пройдены успешно!
```

## 📄 Обновленные файлы

### Импорты исправлены в:
- `lib/ui/file_explorer.rb`
- `lib/ui/code_editor.rb` 
- `editor.rb`
- Все тесты

### Удалены устаревшие файлы:
- `lib/ui/widgets/file_tree_data_source.rb`
- `lib/core/` (вся папка)

## 🎉 Результат

✅ Структура реорганизована по компонентам  
✅ Баги с разворачиванием исправлены  
✅ Проблемы с выделением устранены  
✅ Все тесты проходят  
✅ Код стал чище и модульнее  
✅ Легче поддерживать и развивать 