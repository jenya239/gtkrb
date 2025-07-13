#!/usr/bin/env ruby

puts "🧪 Запуск всех тестов..."

tests = [
  'components/tree_view/tests/file_tree_manager_test.rb',
  'components/tree_view/tests/integration_test.rb',
  'components/tree_view/tests/simple_test.rb'
]

passed = 0
failed = 0

tests.each do |test_file|
  puts "\n" + "="*50
  puts "📋 Запуск: #{test_file}"
  puts "="*50
  
  result = system("ruby #{test_file}")
  
  if result
    passed += 1
    puts "✅ #{test_file} - ПРОЙДЕН"
  else
    failed += 1
    puts "❌ #{test_file} - ПРОВАЛЕН"
  end
end

puts "\n" + "="*50
puts "📊 РЕЗУЛЬТАТЫ:"
puts "✅ Пройдено: #{passed}"
puts "❌ Провалено: #{failed}"
puts "📈 Всего: #{passed + failed}"
puts "="*50

if failed == 0
  puts "🎉 Все тесты пройдены успешно!"
  exit 0
else
  puts "💥 Есть проваленные тесты!"
  exit 1
end 