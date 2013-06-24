#
# raphaeljs binding for Opal
#

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
  N_PUYOS = 2
  ROT = [[[0, 0], [0, -1]],
         [[0, 0], [1, 0]],
         [[0, 0], [0, 1]],
         [[0, 0], [-1, 0]]]
  raise "[bug] invalid ROT" if ROT.any?{|poss| poss.size != N_PUYOS or
                                        poss.any?{|pos| pos.size != 2}}

  def initialize(x, y)
    @puyos = Array.new(N_PUYOS){ Puyo.new }
    @rot = 0
    move(x, y)
  end
  attr_reader :rot

  def self.newrot(rot, dir)
    (rot + dir) % ROT.size
  end

  def self.positions(c, r, rot)
    (0...N_PUYOS).map{|i|
      [c + ROT[rot][i][0], r + ROT[rot][i][1]] 
    }
  end

  def move(x, y)
    @x, @y = x, y

    @puyos.each_with_index do |puyo, i|
      puyo.move(@x + ROT[@rot][i][0] * Puyo::WIDTH,
                @y + ROT[@rot][i][1] * Puyo::HEIGHT)
    end
  end

  def rotate(dir)
    @rot = Pair.newrot(@rot, dir)
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

  def self.col2x(i); x = LEFT + Puyo::WIDTH * i; end
  def self.row2y(j); y = TOP + Puyo::HEIGHT * j; end

  def initialize
    @field = Array.new(ROWS){ Array.new(COLS) }

    @nexts = Nexts.new
    @current = Current.new
  end

  def on_keydown(code)
    case code
    when 37 #left
      @current.move(-1)
    when 39 #right
      @current.move(+1)
    when 40 #down
      drop
    when 90 #z
      @current.rotate(-1)
    when 88 #x
      @current.rotate(+1)
    end
  end

  private

  def drop

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

class Current
  def initialize
    @c = Field::COLS/2 - 1
    @r = 0
    @pair = Pair.new(Field.col2x(@c), Field.row2y(@r))
  end
  attr_reader :c, :r

  def move(dir)
    if valid?(@c + dir, @r, @pair.rot)
      @c += dir
      @pair.move(Field.col2x(@c), Field.row2y(@r))
    end
  end

  def rotate(dir)
    if valid?(@c, @r, Pair.newrot(@pair.rot, dir))
      @pair.rotate(dir)
    else
      move(@c == 0 ? +1 : -1)
      @pair.rotate(dir)
    end
  end

  private

  def valid?(c, r, rot)
    Pair.positions(c, r, rot).all?{|pos|
      (0...Field::COLS).cover?(pos[0])
    }
  end
end

# ---

def onload(&block)
  %x{ window.onload = block }
end

def onkeydown(&block)
  %x{ $(window).on("keydown", function(e){ block(e.keyCode) }) }
end

onload do
  w = Field::WIDTH*2
  h = Field::HEIGHT
  $paper = Raphael(10, 50, w, h)
  bg = $paper.rect(0, 0, w, h)
  bg.attr("fill", "#533")

  field = Field.new

  onkeydown{|code|
    field.on_keydown(code)
  }
end
