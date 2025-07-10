# GTK4 Multi-Editor

Минималистичный редактор кода на Ruby с GTK4 и GtkSourceView5.

## Особенности

- 3 колонки с изменяемым размером
- Подсветка синтаксиса для Ruby, Python и JavaScript
- Номера строк
- Подсветка текущей строки
- Заголовки файлов над каждым редактором
- Растягивание редакторов на всю высоту

## Установка зависимостей

```bash
sudo apt install libgtk-4-dev libgtksourceview-5-dev
gem install gtk4 gtksourceview5
```

## Запуск

```bash
./run_editor.sh
```

или

```bash
GTK_THEME=Adwaita ruby editor.rb
```

## Структура

- `editor.rb` - основной файл приложения
- `run_editor.sh` - скрипт для запуска с правильной темой 