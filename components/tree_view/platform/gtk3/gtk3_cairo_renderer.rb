require_relative '../../presentation/abstract_renderer'
require_relative 'gtk3_render_context'

class GTK3CairoRenderer < AbstractRenderer
  def initialize(theme)
    super(theme)
  end
  
  def render_tree_gtk3(cairo_context, width, height, items, state)
    # Создаем GTK3-специфичный контекст рендеринга
    context = GTK3RenderContext.new(cairo_context, width, height, @theme)
    
    # Используем базовый метод AbstractRenderer
    render_tree(context, items, state)
  end
  
  # Переопределяем render_expander для более аккуратных стрелочек
  def render_expander(context, item, level, y, state)
    exp_x = @theme.expander_x(level)
    exp_y = @theme.expander_center_y(y)
    
    # Более аккуратные и маленькие треугольники
    if state.expanded?(item)
      # Треугольник вниз (развернут) - более тонкий
      context.draw_triangle(
        exp_x - 3, exp_y - 1,
        exp_x + 3, exp_y - 1,
        exp_x, exp_y + 2,
        @theme.expander_color
      )
    else
      # Треугольник вправо (свернут) - более тонкий
      context.draw_triangle(
        exp_x - 1, exp_y - 3,
        exp_x + 2, exp_y,
        exp_x - 1, exp_y + 3,
        @theme.expander_color
      )
    end
  end
end 