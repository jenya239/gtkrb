class FileTreeItem
  attr_reader :name, :path, :type, :parent
  
  def initialize(name:, path:, type:, parent: nil)
    @name = name
    @path = path
    @type = type # :file, :directory, :parent
    @parent = parent
  end
  
  def file?
    @type == :file
  end
  
  def directory?
    @type == :directory
  end
  
  def parent_directory?
    @type == :parent
  end
  
  def can_expand?
    directory? && !parent_directory?
  end
  
  def to_s
    @name
  end
  
  def ==(other)
    other.is_a?(FileTreeItem) && @path == other.path
  end
  
  def hash
    @path.hash
  end
  
  def eql?(other)
    self == other
  end
end 