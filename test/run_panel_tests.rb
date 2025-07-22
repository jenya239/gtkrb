#!/usr/bin/env ruby

puts "=== Запуск всех тестов панелей ==="
puts

# Тест 1: Базовые тесты эвристики
puts "1. Базовые тесты эвристики:"
system("ruby test/panel_type_manager_test.rb")

puts "\n" + "="*50 + "\n"

# Тест 2: Интеграционные тесты
puts "2. Интеграционные тесты:"
system("ruby test/panel_type_manager_integration_test.rb")

puts "\n" + "="*50 + "\n"
puts "Все тесты завершены!" 