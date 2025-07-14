#!/usr/bin/env ruby
# Шаблон для создания нового компонента

if ARGV.length != 1
  puts "Usage: ruby component_template.rb <component_name>"
  puts "Example: ruby component_template.rb button"
  exit 1
end

component_name = ARGV[0]
component_class = component_name.split('_').map(&:capitalize).join

puts "Creating component: #{component_name}"
puts "Class name: #{component_class}"

# Создаем структуру директорий
dirs = [
  "#{component_name}",
  "#{component_name}/core",
  "#{component_name}/presentation", 
  "#{component_name}/input",
  "#{component_name}/platform",
  "#{component_name}/platform/gtk3",
  "#{component_name}/src",
  "#{component_name}/tests",
  "#{component_name}/tests/unit"
]

dirs.each do |dir|
  Dir.mkdir(dir) unless Dir.exist?(dir)
  puts "✓ Created directory: #{dir}"
end

# Создаем базовые файлы
files = {
  # Core Layer
  "#{component_name}/core/#{component_name}_events.rb" => <<~RUBY,
    class #{component_class}Events
      def initialize
        @listeners = {}
      end

      def on(event, &block)
        @listeners[event] ||= []
        @listeners[event] << block
      end

      def emit(event, *args)
        return unless @listeners[event]
        @listeners[event].each { |listener| listener.call(*args) }
      end

      def clear(event = nil)
        if event
          @listeners[event] = []
        else
          @listeners.clear
        end
      end
    end
  RUBY

  "#{component_name}/core/#{component_name}_state.rb" => <<~RUBY,
    class #{component_class}State
      attr_accessor :selected_item

      def initialize
        @selected_item = nil
      end

      def select_item(item)
        @selected_item = item
      end
    end
  RUBY

  "#{component_name}/core/#{component_name}_model.rb" => <<~RUBY,
    class #{component_class}Model
      attr_reader :state

      def initialize(data_source)
        @data_source = data_source
        @state = #{component_class}State.new
      end

      def get_data
        @data_source.fetch
      end

      def can_perform_action?(item)
        item.respond_to?(:actionable?) && item.actionable?
      end
    end
  RUBY

  "#{component_name}/core/#{component_name}_controller.rb" => <<~RUBY,
    class #{component_class}Controller
      attr_reader :state

      def initialize(model, state, events)
        @model = model
        @state = state
        @events = events
      end

      def select_item(item)
        @state.select_item(item)
        @events.emit(:item_selected, item)
      end

      def perform_action(item)
        return unless @model.can_perform_action?(item)
        @events.emit(:action_performed, item)
      end

      def get_data
        @model.get_data
      end
    end
  RUBY

  # Presentation Layer
  "#{component_name}/presentation/#{component_name}_theme.rb" => <<~RUBY,
    class #{component_class}Theme
      attr_reader :item_height, :font_size, :padding

      def initialize
        @item_height = 24
        @font_size = 10
        @padding = 4
      end

      def background_color
        [0.98, 0.98, 0.98, 1.0]
      end

      def selection_color
        [0.4, 0.6, 1.0, 0.3]
      end

      def text_color
        [0.1, 0.1, 0.1, 1.0]
      end

      def item_y(index)
        @padding + (index * (@item_height + @padding))
      end
    end
  RUBY

  "#{component_name}/presentation/render_context.rb" => <<~RUBY,
    class RenderContext
      attr_reader :width, :height, :theme

      def initialize(width, height, theme)
        @width = width
        @height = height
        @theme = theme
      end

      def draw_rectangle(x, y, width, height, color)
        raise NotImplementedError, "Subclass must implement draw_rectangle"
      end

      def draw_text(x, y, text, color)
        raise NotImplementedError, "Subclass must implement draw_text"
      end

      def clear_background(color)
        raise NotImplementedError, "Subclass must implement clear_background"
      end
    end
  RUBY

  "#{component_name}/presentation/abstract_renderer.rb" => <<~RUBY,
    class AbstractRenderer
      def initialize(theme)
        @theme = theme
      end

      def render_component(context, items, state)
        render_background(context)
        
        items.each_with_index do |item, index|
          y = @theme.item_y(index)
          render_item(context, item, y, state)
        end
      end

      def render_background(context)
        context.clear_background(@theme.background_color)
      end

      def render_item(context, item, y, state)
        render_item_background(context, item, y, state)
        render_item_text(context, item, y)
      end

      def render_item_background(context, item, y, state)
        color = if item == state.selected_item
          @theme.selection_color
        else
          @theme.background_color
        end
        
        context.draw_rectangle(0, y, context.width, @theme.item_height, color)
      end

      def render_item_text(context, item, y)
        text_x = @theme.padding
        text_y = y + @theme.item_height - 4
        
        context.draw_text(text_x, text_y, item.name, @theme.text_color)
      end
    end
  RUBY

  # Input Layer
  "#{component_name}/input/input_events.rb" => <<~RUBY,
    class InputEvents
      CLICK = 'click'
      DOUBLE_CLICK = 'double_click'
      KEY_PRESS = 'key_press'

      KEY_ENTER = 'enter'
      KEY_ESCAPE = 'escape'
      KEY_UP = 'up'
      KEY_DOWN = 'down'

      def self.normalize_key(key)
        case key
        when 'Return', 'Enter', 13
          KEY_ENTER
        when 'Escape', 27
          KEY_ESCAPE
        when 'Up', 'ArrowUp'
          KEY_UP
        when 'Down', 'ArrowDown'
          KEY_DOWN
        else
          key.to_s.downcase
        end
      end

      def self.is_navigation_key?(key)
        [KEY_UP, KEY_DOWN].include?(key)
      end

      def self.is_action_key?(key)
        [KEY_ENTER].include?(key)
      end
    end
  RUBY

  "#{component_name}/input/input_controller.rb" => <<~RUBY,
    class InputController
      def initialize(controller, renderer)
        @controller = controller
        @renderer = renderer
      end

      def handle_click(x, y, timestamp = nil)
        # TODO: Implement click handling
        items = @controller.get_data
        # Find item at position and select it
        true
      end

      def handle_key_press(key)
        normalized_key = InputEvents.normalize_key(key)
        
        case normalized_key
        when InputEvents::KEY_ENTER
          # TODO: Implement enter key handling
          true
        else
          false
        end
      end
    end
  RUBY

  # Platform Layer
  "#{component_name}/platform/gtk3/gtk3_render_context.rb" => <<~RUBY,
    require_relative '../../presentation/render_context'

    class GTK3RenderContext < RenderContext
      def initialize(cairo_context, width, height, theme)
        super(width, height, theme)
        @cairo = cairo_context
      end

      def draw_rectangle(x, y, width, height, color)
        @cairo.set_source_rgba(*color)
        @cairo.rectangle(x, y, width, height)
        @cairo.fill
      end

      def draw_text(x, y, text, color)
        @cairo.set_source_rgba(*color)
        @cairo.move_to(x, y)
        @cairo.show_text(text)
      end

      def clear_background(color)
        @cairo.set_source_rgba(*color)
        @cairo.rectangle(0, 0, @width, @height)
        @cairo.fill
      end
    end
  RUBY

  "#{component_name}/platform/gtk3/gtk3_#{component_name}_widget.rb" => <<~RUBY,
    require 'gtk3'
    require_relative '../../core/#{component_name}_controller'
    require_relative '../../core/#{component_name}_events'
    require_relative '../../core/#{component_name}_model'
    require_relative '../../presentation/#{component_name}_theme'
    require_relative '../../input/input_controller'
    require_relative 'gtk3_render_context'

    class GTK3#{component_class}Widget < Gtk::DrawingArea
      attr_reader :controller

      def initialize(data_source)
        super()
        
        # Создаем все слои
        @model = #{component_class}Model.new(data_source)
        @events = #{component_class}Events.new
        @controller = #{component_class}Controller.new(@model, @model.state, @events)
        
        @theme = #{component_class}Theme.new
        @renderer = GTK3#{component_class}Renderer.new(@theme)
        @input_controller = InputController.new(@controller, @renderer)
        
        setup_widget
        setup_callbacks
      end

      def on_item_selected(&block)
        @events.on(:item_selected, &block)
      end

      def on_action_performed(&block)
        @events.on(:action_performed, &block)
      end

      private

      def setup_widget
        set_hexpand(true)
        set_vexpand(true)
        set_size_request(-1, 200)
        
        signal_connect("draw") { |_, cr| draw(cr) }
        signal_connect("button-press-event") { |_, event| handle_click(event) }
        
        add_events(Gdk::EventMask::BUTTON_PRESS_MASK)
        set_can_focus(true)
      end

      def setup_callbacks
        @events.on(:item_selected) { queue_draw }
        @events.on(:action_performed) { queue_draw }
      end

      def draw(cr)
        allocation = self.allocation
        width = allocation.width
        height = allocation.height
        
        items = @controller.get_data
        context = GTK3RenderContext.new(cr, width, height, @theme)
        
        @renderer.render_component(context, items, @controller.state)
      end

      def handle_click(event)
        @input_controller.handle_click(event.x, event.y, event.time / 1000.0)
        false
      end
    end
  RUBY

  # High-level wrapper
  "#{component_name}/src/#{component_name}_wrapper.rb" => <<~RUBY,
    require_relative '../platform/gtk3/gtk3_#{component_name}_widget'

    class #{component_class}Wrapper
      def initialize(data_source)
        @widget = GTK3#{component_class}Widget.new(data_source)
      end

      def widget
        @widget
      end

      def on_item_selected(&block)
        @widget.on_item_selected(&block)
      end

      def on_action_performed(&block)
        @widget.on_action_performed(&block)
      end
    end
  RUBY

  # Tests
  "#{component_name}/tests/unit/core_test.rb" => <<~RUBY,
    require 'minitest/autorun'
    require_relative '../../core/#{component_name}_events'
    require_relative '../../core/#{component_name}_state'
    require_relative '../../core/#{component_name}_model'
    require_relative '../../core/#{component_name}_controller'

    class CoreTest < Minitest::Test
      def setup
        @events = #{component_class}Events.new
        @model = MockModel.new
        @controller = #{component_class}Controller.new(@model, @model.state, @events)
      end

      def test_select_item
        item = MockItem.new("test")
        @controller.select_item(item)
        
        assert_equal item, @controller.state.selected_item
      end
    end

    class MockModel
      attr_reader :state
      
      def initialize
        @state = #{component_class}State.new
      end
      
      def get_data
        [MockItem.new("item1"), MockItem.new("item2")]
      end
      
      def can_perform_action?(item)
        true
      end
    end

    class MockItem
      attr_reader :name
      
      def initialize(name)
        @name = name
      end
    end
  RUBY

  "#{component_name}/tests/run_all_tests.rb" => <<~RUBY,
    #!/usr/bin/env ruby
    require 'minitest/autorun'

    # Load all test files
    Dir[File.join(__dir__, "**/*_test.rb")].each { |file| require file }

    puts "Running all tests for #{component_class}..."
  RUBY
}

# Создаем файлы
files.each do |filename, content|
  File.write(filename, content)
  puts "✓ Created file: #{filename}"
end

puts "\n🎉 Component '#{component_name}' created successfully!"
puts "\nNext steps:"
puts "1. cd #{component_name}"
puts "2. Implement your business logic in core/"
puts "3. Customize rendering in presentation/"
puts "4. Add input handling in input/"
puts "5. Run tests: cd tests && ruby run_all_tests.rb"
puts "\n📖 See CUSTOM_COMPONENT_GUIDE.md for detailed instructions" 