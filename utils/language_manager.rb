require 'gtksourceview3'

class LanguageManager
  def initialize
    @manager = GtkSource::LanguageManager.new
    @language_cache = {}
    @language_map = {
      '.rb' => 'ruby',
      '.py' => 'python', 
      '.js' => 'js',  # Изменил с 'javascript' на 'js'
      '.jsx' => 'js',  # JSX -> JavaScript highlighting
      '.ts' => 'js',  # TypeScript -> JavaScript highlighting
      '.tsx' => 'js',  # TSX -> JavaScript highlighting
      '.html' => 'html',
      '.css' => 'css',
      '.json' => 'json',
      '.xml' => 'xml',
      '.md' => 'markdown',
      '.c' => 'c',
      '.cpp' => 'cpp',
      '.h' => 'c',
      '.hpp' => 'cpp',
      '.java' => 'java',
      '.php' => 'php',
      '.go' => 'go',
      '.rs' => 'rust',
      '.sh' => 'sh',
      '.bash' => 'sh',
      '.yml' => 'yaml',
      '.yaml' => 'yaml',
      '.txt' => 'text'
    }
    
    # Выводим доступные языки для отладки
    puts "Available languages: #{@manager.language_ids.join(', ')}" if ENV['DEBUG_LANGUAGES']
  end

  def get_language(file_path)
    return nil unless file_path
    
    ext = File.extname(file_path).downcase
    lang_name = @language_map[ext]
    return nil unless lang_name
    
    # Используем кэш для ускорения
    return @language_cache[lang_name] if @language_cache.key?(lang_name)
    
    begin
      # Пробуем основное имя
      language = @manager.get_language(lang_name)
      
      # Если не нашли, пробуем альтернативы для JS
      if !language && lang_name == 'js'
        alternatives = ['javascript', 'ecmascript', 'js']
        alternatives.each do |alt|
          language = @manager.get_language(alt)
          break if language
        end
      end
      
      @language_cache[lang_name] = language
      language
    rescue => e
      puts "Warning: Could not get language '#{lang_name}': #{e.message}"
      @language_cache[lang_name] = nil
      nil
    end
  end
  
  def list_available_languages
    @manager.language_ids.sort
  end
end 