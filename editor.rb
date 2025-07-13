require 'gtk3'
require 'gtksourceview3'

# Конфигурация
ENV['GTK_THEME'] = 'Adwaita'
ENV['G_MESSAGES_DEBUG'] = 'none'

# Загружаем модули
require_relative 'utils/language_manager'
require_relative 'lib/ui/file_explorer'
require_relative 'lib/ui/code_editor'
require_relative 'lib/ui/main_window'

window = MainWindow.new(nil)
window.present
Gtk.main 