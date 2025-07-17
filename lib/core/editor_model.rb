class EditorModel
  attr_reader :id, :file_path, :content, :language, :modified
  
  def initialize(id = nil)
    @id = id || "editor_#{rand(1000000)}"
    @file_path = nil
    @content = ""
    @language = nil
    @modified = false
    @observers = []
  end
  
  def load_file(file_path)
    @file_path = file_path
    @content = File.read(file_path) if File.exist?(file_path)
    @language = detect_language(file_path)
    @modified = false
    notify_observers(:file_loaded)
  end
  
  def set_content(content)
    return if @content == content
    @content = content
    @modified = true
    notify_observers(:content_changed)
  end
  
  def save
    return false unless @file_path
    File.write(@file_path, @content)
    @modified = false
    notify_observers(:file_saved)
    true
  end
  
  def save_as(file_path)
    @file_path = file_path
    save
  end
  
  def new_file
    @file_path = nil
    @content = ""
    @modified = false
    @language = nil
    notify_observers(:new_file)
  end
  
  def add_observer(&block)
    @observers << block
  end
  
  def modified?
    @modified
  end
  
  def has_file?
    !@file_path.nil?
  end
  
  def display_name
    return "untitled" unless @file_path
    File.basename(@file_path)
  end
  
  private
  
  def detect_language(file_path)
    return nil unless file_path
    
    ext = File.extname(file_path).downcase
    case ext
    when '.rb' then 'ruby'
    when '.js' then 'javascript'
    when '.ts' then 'typescript'
    when '.py' then 'python'
    when '.md' then 'markdown'
    when '.html' then 'html'
    when '.css' then 'css'
    else nil
    end
  end
  
  def notify_observers(event)
    @observers.each { |obs| obs.call(self, event) }
  end
end 