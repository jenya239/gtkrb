require 'gtksourceview5'

class LanguageManager
  def initialize
    @manager = GtkSource::LanguageManager.new
    @language_map = {
      '.rb' => 'ruby',
      '.py' => 'python', 
      '.js' => 'javascript',
      '.html' => 'html',
      '.css' => 'css',
      '.json' => 'json'
    }
  end

  def get_language(file_path)
    ext = File.extname(file_path).downcase
    lang_name = @language_map[ext]
    @manager.get_language(lang_name) if lang_name
  end
end 