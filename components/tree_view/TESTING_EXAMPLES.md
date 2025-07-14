# Testing Examples

## Mock Renderer для тестирования

```ruby
class MockRenderer < AbstractRenderer
  attr_reader :rendered_items, :background_rendered
  
  def initialize(theme)
    super(theme)
    @rendered_items = []
    @background_rendered = false
  end
  
  def render_background(context)
    @background_rendered = true
  end
  
  def render_item(context, item, level, y, state)
    @rendered_items << {
      item: item,
      level: level,
      y: y,
      selected: state.selected?(item),
      expanded: state.expanded?(item)
    }
  end
end
```

## Mock RenderContext

```ruby
class MockRenderContext < RenderContext
  attr_reader :rectangles, :texts, :icons
  
  def initialize(width = 200, height = 300)
    @width = width
    @height = height
    @rectangles = []
    @texts = []
    @icons = []
  end
  
  def draw_rectangle(x, y, width, height, color)
    @rectangles << { x: x, y: y, width: width, height: height, color: color }
  end
  
  def draw_text(x, y, text, font, color)
    @texts << { x: x, y: y, text: text, font: font, color: color }
  end
  
  def draw_icon(x, y, icon)
    @icons << { x: x, y: y, icon: icon }
  end
end
```

## Полные тесты компонентов

```ruby
describe TreeController do
  let(:model) { MockTreeModel.new }
  let(:state) { TreeState.new }
  let(:events) { TreeEvents.new }
  let(:controller) { TreeController.new(model, state, events) }
  
  describe "#expand_item" do
    it "expands expandable items" do
      item = model.create_folder("folder1")
      
      controller.expand_item(item)
      
      expect(state.expanded?(item)).to be true
    end
    
    it "emits tree_changed event" do
      item = model.create_folder("folder1")
      events_emitted = []
      events.on(:tree_changed) { events_emitted << :tree_changed }
      
      controller.expand_item(item)
      
      expect(events_emitted).to include(:tree_changed)
    end
    
    it "does not expand files" do
      item = model.create_file("file1.txt")
      
      controller.expand_item(item)
      
      expect(state.expanded?(item)).to be false
    end
  end
  
  describe "#select_item" do
    it "selects items" do
      item = model.create_file("file1.txt")
      
      controller.select_item(item)
      
      expect(state.selected_item).to eq(item)
    end
    
    it "emits item_selected event" do
      item = model.create_file("file1.txt")
      selected_items = []
      events.on(:item_selected) { |item| selected_items << item }
      
      controller.select_item(item)
      
      expect(selected_items).to include(item)
    end
  end
  
  describe "#handle_key" do
    before do
      3.times { |i| model.create_file("file#{i}.txt") }
      controller.select_item(model.items[0])
    end
    
    it "selects next item on down key" do
      controller.handle_key(:down)
      
      expect(state.selected_item).to eq(model.items[1])
    end
    
    it "selects previous item on up key" do
      controller.select_item(model.items[1])
      
      controller.handle_key(:up)
      
      expect(state.selected_item).to eq(model.items[0])
    end
    
    it "activates selected item on enter key" do
      activated_items = []
      events.on(:item_activated) { |item| activated_items << item }
      
      controller.handle_key(:enter)
      
      expect(activated_items).to include(model.items[0])
    end
  end
end
```

## Тестирование рендеринга

```ruby
describe AbstractRenderer do
  let(:theme) { TreeTheme.new }
  let(:renderer) { MockRenderer.new(theme) }
  let(:context) { MockRenderContext.new }
  let(:state) { TreeState.new }
  
  describe "#render_tree" do
    it "renders background" do
      items = []
      
      renderer.render_tree(context, items, state)
      
      expect(renderer.background_rendered).to be true
    end
    
    it "renders all items" do
      items = [
        [FileTreeItem.new(name: "file1.txt", type: :file), 0],
        [FileTreeItem.new(name: "folder1", type: :directory), 0],
        [FileTreeItem.new(name: "file2.txt", type: :file), 1]
      ]
      
      renderer.render_tree(context, items, state)
      
      expect(renderer.rendered_items.length).to eq(3)
      expect(renderer.rendered_items[0][:item].name).to eq("file1.txt")
      expect(renderer.rendered_items[1][:item].name).to eq("folder1")
      expect(renderer.rendered_items[2][:item].name).to eq("file2.txt")
    end
    
    it "renders items with correct levels" do
      items = [
        [FileTreeItem.new(name: "root", type: :directory), 0],
        [FileTreeItem.new(name: "child", type: :file), 1]
      ]
      
      renderer.render_tree(context, items, state)
      
      expect(renderer.rendered_items[0][:level]).to eq(0)
      expect(renderer.rendered_items[1][:level]).to eq(1)
    end
    
    it "marks selected items" do
      item = FileTreeItem.new(name: "selected", type: :file)
      state.select(item)
      items = [[item, 0]]
      
      renderer.render_tree(context, items, state)
      
      expect(renderer.rendered_items[0][:selected]).to be true
    end
  end
end
```

## Тестирование InputController

```ruby
describe InputController do
  let(:tree_controller) { double("TreeController") }
  let(:input_controller) { InputController.new(tree_controller) }
  
  describe "#handle_click" do
    it "selects item on single click" do
      allow(input_controller).to receive(:find_item_at_position).and_return(:some_item)
      expect(tree_controller).to receive(:select_item).with(:some_item)
      
      input_controller.handle_click(10, 20, double_click: false)
    end
    
    it "activates item on double click" do
      allow(input_controller).to receive(:find_item_at_position).and_return(:some_item)
      expect(tree_controller).to receive(:activate_item).with(:some_item)
      
      input_controller.handle_click(10, 20, double_click: true)
    end
    
    it "does nothing if no item at position" do
      allow(input_controller).to receive(:find_item_at_position).and_return(nil)
      expect(tree_controller).not_to receive(:select_item)
      
      input_controller.handle_click(10, 20)
    end
  end
  
  describe "#handle_key" do
    it "delegates to tree controller" do
      expect(tree_controller).to receive(:handle_key).with(:up)
      
      input_controller.handle_key(:up)
    end
  end
  
  describe "#handle_scroll" do
    it "delegates to tree controller" do
      expect(tree_controller).to receive(:scroll_by).with(50)
      
      input_controller.handle_scroll(50)
    end
  end
end
```

## Интеграционное тестирование

```ruby
describe "Tree Component Integration" do
  let(:model) { FileTreeModel.new("/tmp/test") }
  let(:state) { TreeState.new }
  let(:events) { TreeEvents.new }
  let(:controller) { TreeController.new(model, state, events) }
  let(:renderer) { MockRenderer.new(TreeTheme.new) }
  let(:input_controller) { InputController.new(controller) }
  
  before do
    # Создаем тестовую структуру файлов
    Dir.mkdir("/tmp/test") unless Dir.exist?("/tmp/test")
    Dir.mkdir("/tmp/test/folder1") unless Dir.exist?("/tmp/test/folder1")
    File.write("/tmp/test/file1.txt", "content")
    File.write("/tmp/test/folder1/file2.txt", "content")
  end
  
  after do
    FileUtils.rm_rf("/tmp/test")
  end
  
  it "complete workflow: expand folder, select file" do
    # Получаем элементы
    items = controller.get_visible_items
    folder = items.find { |item, level| item.name == "folder1" }&.first
    
    # Раскрываем папку
    controller.expand_item(folder)
    
    # Проверяем что папка раскрыта
    expect(state.expanded?(folder)).to be true
    
    # Получаем обновленный список
    items = controller.get_visible_items
    nested_file = items.find { |item, level| item.name == "file2.txt" }&.first
    
    # Выбираем файл
    controller.select_item(nested_file)
    
    # Проверяем что файл выбран
    expect(state.selected_item).to eq(nested_file)
  end
end
```

## Преимущества для тестирования

1. **Полная изоляция**: Каждый слой тестируется независимо
2. **Простые моки**: Легко создавать mock-объекты для тестов
3. **Быстрые тесты**: Нет GUI инициализации
4. **Детальное тестирование**: Можно протестировать каждый аспект
5. **Интеграционные тесты**: Можно тестировать взаимодействие слоев

## Запуск тестов

```bash
# Тесты core логики (быстрые)
ruby -I components/tree_view test/unit/core_test.rb

# Тесты рендеринга (без GUI)
ruby -I components/tree_view test/unit/renderer_test.rb

# Интеграционные тесты
ruby -I components/tree_view test/integration/tree_integration_test.rb

# Все тесты
ruby -I components/tree_view test/run_all_tests.rb
``` 