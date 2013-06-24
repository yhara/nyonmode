def Raphael(a, b, c, d)
  `Raphael(a, b, c, d)`
end

class Paper < `Raphael`
  alias_native :circle, :circle
  alias_native :rect, :rect
end

class Element < `Raphael.el.constructor`
  alias_native :attr, :attr
end

# ---

class Puyo
  RADIUS = 15
  WIDTH = HEIGHT = DIAMETER = RADIUS*2

  #           purple red green blue yellow
  COLORS = %w(#9b59b6 #e74c3c #27ae60 #3498db #f1c40f)

  def initialize(i, j)
    @color = COLORS.shuffle.first

    @circle = $paper.circle(-RADIUS*2, -RADIUS*2, RADIUS)
    @circle.attr("fill", @color)
    #@circle.attr("stroke", "#fff")

    move(i, j)
  end

  def move(i, j)
    @i, @j = i, j

    @circle.attr("cx", Field::LEFT + (DIAMETER * @i) + RADIUS)
    @circle.attr("cy", Field::LEFT + (DIAMETER * @j) + RADIUS)
  end
end

class Field
  TOP = 0
  LEFT = 0
  COLS = 6
  ROWS = 14
  WIDTH = Puyo::WIDTH * COLS
  HEIGHT = Puyo::HEIGHT * ROWS

  def initialize
    @field = Array.new(ROWS){ Array.new(COLS) }

    (2...ROWS).each do |j|
      COLS.times do |i|
        @field[j][i] = Puyo.new(i, j)
      end
    end
  end
end

# ---

def onload(&block)
  %x{ window.onload = block }
end

onload do
  $paper = Raphael(10, 50, Field::WIDTH, Field::HEIGHT)
  bg = $paper.rect(0, 0, Field::WIDTH, Field::HEIGHT)
  bg.attr("fill", "black")

  field = Field.new
end
