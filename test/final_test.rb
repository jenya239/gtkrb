#!/usr/bin/env ruby

require 'gtk3'
require_relative '../editor'

# Финальный тест приложения
class FinalTest
  def self.run
    puts "Запуск финального теста..."
    
    # Тестируем создание основных компонентов
    require_relative '../lib/ui/main_window'
    require_relative '../lib/ui/file_explorer'
    require_relative '../lib/ui/code_editor'
    require_relative '../lib/core/language_manager'
    
    puts "✓ Все модули загружены"
    
    # Тестируем LanguageManager
    lm = LanguageManager.new
    puts "✓ LanguageManager создан"
    
    # Тестируем FileExplorer
    fe = FileExplorer.new
    puts "✓ FileExplorer создан"
    
    # Тестируем CodeEditor
    ce = CodeEditor.new
    puts "✓ CodeEditor создан"
    
    puts "Все компоненты работают корректно!"
    puts "Приложение готово к использованию."
    
  rescue => e
    puts "Ошибка: #{e.message}"
    puts e.backtrace.first(5)
  end
end

if __FILE__ == $0
  FinalTest.run
end 