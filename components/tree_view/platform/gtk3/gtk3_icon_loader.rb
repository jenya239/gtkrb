require 'gtk3'

class GTK3IconLoader
  def initialize
    @icons = {}
    load_icons
  end
  
  def get_icon(icon_type)
    @icons[icon_type] || @icons[:file]
  end
  
  private
  
  def load_icons
    icon_path = File.expand_path('../../../../icons', __FILE__)
    
    @icons[:file] = load_icon_file(File.join(icon_path, 'file.png'))
    @icons[:folder] = load_icon_file(File.join(icon_path, 'folder.png'))
    @icons[:up] = load_icon_file(File.join(icon_path, 'up.png'))
  end
  
  def load_icon_file(path)
    return nil unless File.exist?(path)
    
    begin
      GdkPixbuf::Pixbuf.new(file: path, width: 12, height: 12)
    rescue => e
      puts "Warning: Could not load icon from #{path}: #{e.message}"
      nil
    end
  end
end 