# GTK3 Ruby Editor

Простой текстовый редактор на Ruby с GTK3.

## Установка зависимостей

```bash
sudo apt install ruby-gtk3 libgtk-3-dev libgtksourceview-3.0-dev
gem install gtksourceview3
```

## Запуск

```bash
ruby editor.rb
```

## Структура проекта

- `editor.rb` - точка входа
- `lib/ui/` - пользовательский интерфейс
- `lib/core/` - основная логика
- `test/` - тесты

## Возможности

- Файловый браузер
- Подсветка синтаксиса
- Минимап
- Виртуализированное дерево файлов 

test