require 'cairo'

ICONS = {
  folder: 'folder.png',
  file:   'file.png',
  up:     'up.png'
}

SIZE = 16

# Folder icon (желтая папка)
Cairo::ImageSurface.new(:argb32, SIZE, SIZE) do |surface|
  cr = Cairo::Context.new(surface)
  cr.set_source_rgb(0.98, 0.82, 0.25) # желтый
  cr.rectangle(2, 7, 12, 7)
  cr.fill
  cr.set_source_rgb(0.93, 0.68, 0.13)
  cr.rectangle(2, 4, 6, 4)
  cr.fill
  surface.write_to_png("folder.png")
end

# File icon (белый лист)
Cairo::ImageSurface.new(:argb32, SIZE, SIZE) do |surface|
  cr = Cairo::Context.new(surface)
  cr.set_source_rgb(1, 1, 1)
  cr.rectangle(3, 3, 10, 10)
  cr.fill
  cr.set_source_rgb(0.7, 0.7, 0.7)
  cr.rectangle(3, 3, 10, 10)
  cr.stroke
  surface.write_to_png("file.png")
end

# Up icon (стрелка вверх)
Cairo::ImageSurface.new(:argb32, SIZE, SIZE) do |surface|
  cr = Cairo::Context.new(surface)
  cr.set_source_rgb(0.4, 0.6, 0.2)
  cr.move_to(8, 3)
  cr.line_to(13, 10)
  cr.line_to(10, 10)
  cr.line_to(10, 14)
  cr.line_to(6, 14)
  cr.line_to(6, 10)
  cr.line_to(3, 10)
  cr.close_path
  cr.fill
  surface.write_to_png("up.png")
end 