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
  alias_native :remove, :remove
end

# ---

# Represents a single puyo. Holds a Raphael circle
class Puyo
  RADIUS = 15
  WIDTH = HEIGHT = DIAMETER = RADIUS*2

  #           purple red green blue yellow
  COLORS = %w(#9b59b6 #e74c3c #27ae60 #3498db #f1c40f)

  def initialize(x=nil, y=nil)
    @color = COLORS.shuffle.first
    move(x, y) if x && y
  end
  attr_reader :color

  def move(x, y)
    @x, @y = x, y

    @circle ||= render
    @circle.attr("cx", @x + RADIUS)
    @circle.attr("cy", @y + RADIUS)
  end

  def remove
    @circle.remove
  end

  private

  def render
    circle = $paper.circle(-RADIUS*2, -RADIUS*2, RADIUS)
    circle.attr("fill", @color)
    circle.attr("stroke", "#422")
    return circle
  end
end

# Represents a pair of puyo, both in the field and next area.
class Pair
  N_PUYOS = 2
  ROT = [[[0, 0], [0, -1]],
         [[0, 0], [1, 0]],
         [[0, 0], [0, 1]],
         [[0, 0], [-1, 0]]]
  raise "[bug] invalid ROT" if ROT.any?{|poss| poss.size != N_PUYOS or
                                        poss.any?{|pos| pos.size != 2}}

  def initialize(x=nil, y=nil)
    @puyos = Array.new(N_PUYOS){ Puyo.new }
    @rot = 0
    move(x, y) if x && y
  end
  attr_reader :puyos, :rot

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

# Main class. Represents 6x14 play field.
class Field
  COLS = 6
  ROWS = 14
  TOP  = Puyo::HEIGHT
  LEFT = 0
  WIDTH  = Puyo::WIDTH  * COLS
  HEIGHT = Puyo::HEIGHT * (ROWS + 1)
  RIGHT  = LEFT + WIDTH
  BOTTOM = TOP  + HEIGHT

  def self.col2x(i); x = LEFT + Puyo::WIDTH * i; end
  def self.row2y(j); y = TOP + Puyo::HEIGHT * j; end

  def initialize
    @field = Array.new(ROWS){ Array.new(COLS) }
    @state = :normal

    @nexts = Nexts.new
    @current = Current.new(@nexts.shift)
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

  def move_puyo(puyo, c, r)
    puyo.move(Field.col2x(c), Field.row2y(r))
  end

  def drop
    poss = @current.positions
    (0...Pair::N_PUYOS).to_a.sort{|a, b|
      poss[b][1] <=> poss[a][1]
    }.each do |i|
      c, r = *poss[i]
      drop_r = (0...ROWS).to_a.reverse.find{|rr|
                 @field[rr][c].nil?
               } || 0
      @field[drop_r][c] = @current.pair.puyos[i]
      move_puyo(@current.pair.puyos[i], c, drop_r)
    end

    @current = Current.new(@nexts.shift)
    envanish
  end

  NEIGHBORS = [[+1, 0], [0, +1], [-1, 0], [0, -1]]
  VANISH_COUNT = 4
  def envanish
    state = :vanishing

    # Mark empty cells as already visited
    visited = @field.map{|row| row.map{|cell| cell.nil? ? true : false}}
    to_vanish = []
    q = [[0, ROWS-1]] # start from bottom left corner
    while (pos = next_visible_pos(visited))
      poss = connected_visible_puyos(pos[0], pos[1], visited)
      to_vanish.concat(poss) if poss.length >= VANISH_COUNT
    end

    # Remove puyos
    to_vanish.each do |pos|
      @field[pos[1]][pos[0]].remove
      @field[pos[1]][pos[0]] = nil
    end

    timer(1) do
      # Drop puyos
      (0...ROWS).to_a.reverse.each do |j|
        (0...COLS).each do |i|
          if @field[j][i].nil? and (jj = (0...j).find{|jj| @field[jj][i] != nil})
            move_puyo(@field[jj][i], i, j)
            @field[j][i] = @field[jj][i]
            @field[jj][i] = nil
          end
        end
      end

      state = :normal
    end
  end

  private

  def timer(sec, &block)
    %x{ setTimeout(block, sec*1000) }
  end

  # Returns a position not visited yet, or return nil if there are none.
  # Invisible area (c==0, 1) are not counted.
  def next_visible_pos(visited)
    # Note: due to bug of opal 0.3.44, cannot escape from method with +return+ in a block
    ret = nil
    (2...ROWS).each do |j|
      (0...COLS).each do |i|
        if not visited[j][i]
          ret ||= [i, j]
        end
      end
    end
    return ret
  end

  # Returns positions of puyos of the same color as (c, r).
  # Invisible area (c==0, 1) are not counted.
  # Destructively updates +visited+.
  def connected_visible_puyos(c, r, visited)
    col = @field[r][c].color
    poss = [[c, r]]
    q = [[c, r]]
    until q.empty?
      i, j = *q.shift
      visited[j][i] = true
      NEIGHBORS.each do |dij|
        di, dj = *dij
        ni, nj = i+di, j+dj
        next unless (0...COLS)===ni && (2...ROWS)===nj
        next if visited[nj][ni]

        if @field[nj][ni].color == col
          poss.push([ni, nj])
          q.push([ni, nj])
        end
      end
    end

    return poss
  end
end

# Represents next area (N pairs).
class Nexts
  N_PAIRS = 2

  LEFT = Field::RIGHT + Puyo::WIDTH
  TOP  = Field::TOP + Puyo::HEIGHT/2

  def initialize
    @pairs = Array.new(N_PAIRS){ Pair.new }
    rearrange
  end

  def shift
    next_pair = @pairs.shift
    @pairs.push(Pair.new)
    rearrange
    return next_pair
  end

  private

  def rearrange
    @pairs.each_with_index do |pair, i|
      x = LEFT + Puyo::WIDTH * (i*1.5)
      y = Nexts::TOP
      pair.move(x, y)
    end
  end
end

# Represents the current pair.
# Handles validation of moving/rotation.
class Current
  def initialize(pair)
    @c = Field::COLS/2 - 1
    @r = 0
    @pair = pair
    @pair.move(Field.col2x(@c), Field.row2y(@r))
  end
  attr_reader :c, :r, :pair

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

  def positions
    Pair.positions(@c, @r, @pair.rot)
  end

  private

  def valid?(c, r, rot)
    Pair.positions(c, r, rot).all?{|pos|
      (0...Field::COLS).cover?(pos[0])
    }
  end
end

# ---

# main

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
