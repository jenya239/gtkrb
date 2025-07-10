require 'gtk4'
require 'gtksourceview5'

app = Gtk::Application.new("org.example.editor", :default_flags)
app.signal_connect "activate" do |application|
  win = Gtk::ApplicationWindow.new(application)
  win.set_title("Editor")
  win.set_default_size(800, 600)
  
  view = GtkSource::View.new
  buffer = view.buffer
  manager = GtkSource::LanguageManager.new
  buffer.language = manager.get_language('ruby')
  
  # Создаем 3 редактора с заголовками
  # Редактор 1 - Ruby
  label1 = Gtk::Label.new("main.rb")
  label1.set_margin_start(10)
  label1.set_margin_end(10)
  label1.set_margin_top(5)
  label1.set_margin_bottom(5)
  
  view1 = GtkSource::View.new
  buffer1 = view1.buffer
  buffer1.language = manager.get_language('ruby')
  buffer1.text = "class Calculator\n  def add(a, b)\n    a + b\n  end\n  \n  def multiply(a, b)\n    a * b\n  end\nend\n\ncalc = Calculator.new\nputs calc.add(5, 3)\nputs calc.multiply(4, 7)"
  view1.set_show_line_numbers(true)
  view1.set_highlight_current_line(true)
  
  box1 = Gtk::Box.new(:vertical, 0)
  box1.append(label1)
  box1.append(view1)
  view1.set_vexpand(true)  # Растягивать по вертикали
  
  # Редактор 2 - Python
  label2 = Gtk::Label.new("app.py")
  label2.set_margin_start(10)
  label2.set_margin_end(10)
  label2.set_margin_top(5)
  label2.set_margin_bottom(5)
  
  view2 = GtkSource::View.new
  buffer2 = view2.buffer
  buffer2.language = manager.get_language('python')
  buffer2.text = "import requests\n\ndef fetch_data(url):\n    try:\n        response = requests.get(url)\n        response.raise_for_status()\n        return response.json()\n    except requests.RequestException as e:\n        print(f\"Error: {e}\")\n        return None\n\n# Example usage\ndata = fetch_data(\"https://api.example.com/data\")\nif data:\n    print(data)"
  view2.set_show_line_numbers(true)
  view2.set_highlight_current_line(true)
  
  box2 = Gtk::Box.new(:vertical, 0)
  box2.append(label2)
  box2.append(view2)
  view2.set_vexpand(true)  # Растягивать по вертикали
  
  # Редактор 3 - JavaScript
  label3 = Gtk::Label.new("script.js")
  label3.set_margin_start(10)
  label3.set_margin_end(10)
  label3.set_margin_top(5)
  label3.set_margin_bottom(5)
  
  view3 = GtkSource::View.new
  buffer3 = view3.buffer
  # Попробуем разные варианты для JavaScript
  js_lang = manager.get_language('javascript') || manager.get_language('js') || manager.get_language('text/javascript')
  buffer3.language = js_lang
  buffer3.text = "class UserManager {\n  constructor() {\n    this.users = [];\n  }\n  \n  addUser(user) {\n    this.users.push(user);\n    console.log(`User ${user.name} added`);\n  }\n  \n  findUser(id) {\n    return this.users.find(user => user.id === id);\n  }\n}\n\nconst manager = new UserManager();\nmanager.addUser({ id: 1, name: 'John' });"
  view3.set_show_line_numbers(true)
  view3.set_highlight_current_line(true)
  
  box3 = Gtk::Box.new(:vertical, 0)
  box3.append(label3)
  box3.append(view3)
  view3.set_vexpand(true)  # Растягивать по вертикали
  
  # Горизонтальный layout с изменяемыми колонками
  paned1 = Gtk::Paned.new(:horizontal)
  paned1.set_start_child(box1)
  paned1.set_end_child(box2)
  # Устанавливаем равные размеры после создания окна
  paned1.set_position(800 / 3)  # Равная ширина
  
  paned2 = Gtk::Paned.new(:horizontal)
  paned2.set_start_child(paned1)
  paned2.set_end_child(box3)
  paned2.set_position(800 * 2 / 3)  # Равная ширина
  
  win.set_child(paned2)
  win.present
end

app.run 