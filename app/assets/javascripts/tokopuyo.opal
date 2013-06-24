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

  def initialize(x=nil, y=nil)
    @color = COLORS.shuffle.first
    move(x, y) if x && y
  end

  def move(x, y)
    @x, @y = x, y

    @circle ||= render
    @circle.attr("cx", @x + RADIUS)
    @circle.attr("cy", @y + RADIUS)
  end

  private

  def render
    circle = $paper.circle(-RADIUS*2, -RADIUS*2, RADIUS)
    circle.attr("fill", @color)
    circle.attr("stroke", "#422")
    return circle
  end
end

class Pair
  ROT = [[0, -1], [1, 0], [0, 1], [-1, 0]]

  def initialize(x, y)
    @puyos = Array.new(2){ Puyo.new }
    @rot = 0
    move(x, y)
  end

  def move(x, y)
    @x, @y = x, y

    @puyos[0].move(@x, @y)
    @puyos[1].move(@x + ROT[@rot][0] * Puyo::WIDTH,
                   @y + ROT[@rot][1] * Puyo::HEIGHT)
  end

  def rot(dir)
    @rot = (@rot + (dir > 0 ? +1 : -1)) % ROT.size
    move(@x, @y)
  end
end

class Field
  COLS = 6
  ROWS = 14
  TOP  = Puyo::HEIGHT
  LEFT = 0
  WIDTH  = Puyo::WIDTH  * COLS
  HEIGHT = Puyo::HEIGHT * ROWS
  RIGHT  = LEFT + WIDTH
  BOTTOM = TOP  + HEIGHT

  def initialize
    @field = Array.new(ROWS){ Array.new(COLS) }

    (2...ROWS).each do |j|
      COLS.times do |i|
        x = LEFT + Puyo::WIDTH * i
        y = TOP + Puyo::HEIGHT * j
        @field[j][i] = Puyo.new(x, y)
      end
    end
  end
end

class Nexts
  N_PAIRS = 2

  LEFT = Field::RIGHT + Puyo::WIDTH
  TOP  = Field::TOP + Puyo::HEIGHT/2

  def initialize
    @pairs = Array.new(N_PAIRS){|i|
      x = LEFT + Puyo::WIDTH * (i*1.5)
      y = Nexts::TOP
      Pair.new(x, y)
    }
  end
end


# ---

def onload(&block)
  %x{ window.onload = block }
end

onload do
  w = Field::WIDTH*2
  h = Field::HEIGHT
  $paper = Raphael(10, 50, w, h)
  bg = $paper.rect(0, 0, w, h)
  bg.attr("fill", "#533")

  field = Field.new
  nexts = Nexts.new
end
