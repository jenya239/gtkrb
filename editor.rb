require 'gtk4'
require 'gtksourceview5'

# Конфигурация
ENV['GTK_THEME'] = 'Adwaita'
ENV['G_MESSAGES_DEBUG'] = 'none'

# Загружаем модули
require_relative 'lib/core/language_manager'
require_relative 'lib/ui/file_explorer'
require_relative 'lib/ui/code_editor'
require_relative 'lib/ui/main_window'

# Точка входа
app = Gtk::Application.new("org.example.editor", :default_flags)
app.signal_connect "activate" do |application|
  window = MainWindow.new(application)
  window.present
end

app.run 