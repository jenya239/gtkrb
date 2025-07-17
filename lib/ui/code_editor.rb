require 'gtk3'
require 'gtksourceview3'
require_relative '../../utils/language_manager'
require_relative 'widgets/minimap'

class CodeEditor
  def initialize
    @view = GtkSource::View.new
    @buffer = @view.buffer
    @language_manager = LanguageManager.new
    @file_path = nil
    @modified = false
    @highlighting_enabled = true
    @current_load_id = 0
    @pending_highlight_sources = []
    
    # Создаем ScrolledWindow один раз
    @scrolled = Gtk::ScrolledWindow.new
    @scrolled.add(@view)
    @scrolled.set_hexpand(true)
    @scrolled.set_vexpand(true)
    
    setup_editor
  end

  def widget
    @scrolled
  end

  def load_file(file_path)
    @file_path = file_path
    @current_load_id += 1
    load_id = @current_load_id
    
    # Отменяем все предыдущие асинхронные операции
    cancel_pending_highlights
    
    # Принудительно сбрасываем язык перед каждой загрузкой
    @buffer.language = nil
    
    # Фаза 1: Быстрая загрузка контента
    load_content_fast(file_path, load_id)
    
    # Фаза 2: Отложенная установка подсветки (с защитой)
    apply_syntax_highlighting(file_path, load_id)
  end

  def save_file
    return unless @file_path
    File.write(@file_path, @buffer.text)
    @modified = false
    emit_modified
  end

  def modified?
    @modified
  end

  def reset_modified
    @modified = false
    emit_modified
  end

  def file_path
    @file_path
  end

  def on_modified(&block)
    @on_modified = block
  end

  def get_content
    @buffer.text
  end

  def set_content(content)
    @buffer.text = content
    @modified = false
  end

  def on_save_request(&block)
    @on_save_request = block
  end

  def request_save
    @on_save_request.call if @on_save_request
  end

  def force_refresh_highlighting
    return unless @file_path && @highlighting_enabled
    
    puts "Force refreshing highlighting for #{@file_path}"
    cancel_pending_highlights
    apply_syntax_highlighting(@file_path, @current_load_id)
  end

  def toggle_highlighting
    @highlighting_enabled = !@highlighting_enabled
    puts "Highlighting #{@highlighting_enabled ? 'enabled' : 'disabled'}"
    
    if @highlighting_enabled && @file_path
      apply_syntax_highlighting(@file_path, @current_load_id)
    else
      cancel_pending_highlights
      @buffer.language = nil
    end
  end

  private

  def cancel_pending_highlights
    @pending_highlight_sources.each do |source_id|
      GLib::Source.remove(source_id) if source_id
    end
    @pending_highlight_sources.clear
  end

  def load_content_fast(file_path, load_id)
    begin
      # Проверяем валидность загрузки
      return if load_id != @current_load_id
      
      content = File.read(file_path)
      
      # Еще раз проверяем перед применением
      return if load_id != @current_load_id || @file_path != file_path
      
      # Быстрая загрузка только контента
      @buffer.text = content
      @modified = false
      emit_modified
      
      puts "File loaded: #{file_path} (#{content.length} chars)"
      
    rescue => e
      # Применяем ошибку только если это все еще актуальная загрузка
      if load_id == @current_load_id && @file_path == file_path
        @buffer.text = "# Error reading file: #{e.message}"
        @buffer.language = nil
        @modified = false
        emit_modified
      end
    end
  end

  def apply_syntax_highlighting(file_path, load_id)
    return unless @highlighting_enabled
    
    # Применяем подсветку в следующем цикле событий
    source_id = GLib::Idle.add do
      # Удаляем себя из списка pending
      @pending_highlight_sources.delete(source_id)
      
      # Проверяем что файл все еще актуален (более мягкая проверка)
      unless @file_path == file_path
        puts "Skipping highlighting for #{file_path} (different file now: #{@file_path})"
        next false
      end
      
      begin
        # Проверяем существование файла
        unless File.exist?(file_path)
          puts "Skipping highlighting for #{file_path} (file not found)"
          next false
        end
        
        # Определяем размер файла для оптимизации
        file_size = File.size(file_path)
        
        if file_size > 1_000_000  # 1MB
          # Для больших файлов отключаем подсветку
          puts "Large file detected, syntax highlighting disabled for #{file_path}"
          @buffer.language = nil
        else
          # Для обычных файлов применяем подсветку
          lang = @language_manager.get_language(file_path)
          
          if lang
            # Применяем язык если мы все еще на том же файле
            if @file_path == file_path
              @buffer.language = lang
              puts "Syntax highlighting applied: #{lang.name} for #{file_path}"
            else
              puts "File changed during highlighting, skipping for #{file_path}"
            end
          else
            puts "No language found for #{file_path}"
          end
        end
        
      rescue => e
        puts "Error applying syntax highlighting for #{file_path}: #{e.message}"
        # Не блокируем из-за ошибки, просто логируем
      end
      
      false # Убираем из очереди
    end
    
    # Сохраняем ID источника для возможной отмены
    @pending_highlight_sources << source_id
  end

  def setup_editor
    @view.set_show_line_numbers(true)
    @view.set_monospace(true)
    @view.set_tab_width(2)
    @view.set_auto_indent(true)
    @view.set_indent_width(2)
    
    # Обработка изменений
    @buffer.signal_connect('changed') { mark_modified }
    
    # Обработка горячих клавиш
    @view.signal_connect('key-press-event') do |widget, event|
      if event.state.control_mask? && event.keyval == Gdk::Keyval::KEY_s
        request_save
        true
      else
        false
      end
    end
  end

  def emit_modified
    @on_modified.call if @on_modified
  end

  def mark_modified
    unless @modified
      @modified = true
      emit_modified
    end
  end
end 