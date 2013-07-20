# Include underscore for spec/javascripts/
#= require underscore

window.p = (args...) -> console.log(args...)
window.pp = (args...) -> console.log(args.map(JSON.stringify)...)

# Represents a single puyo. Holds a Raphael circle
class Puyo
  @RADIUS: 15
  @WIDTH = @HEIGHT = @DIAMETER = @RADIUS*2

  #           purple red green blue yellow
  @COLORS: ["#9b59b6", "#e74c3c", "#27ae60", "#3498db"]#, "#f1c40f"]

  constructor: (x=null, y=null, colorIdx=null) ->
    colorIdx ?= Math.floor(Math.random()*Puyo.COLORS.length)
    @color = Puyo.COLORS[colorIdx]
    @move(x, y) if x && y

  move: (x, y) ->
    [@x, @y] = [x, y]
    
    @circle ?= @_render()
    @circle.attr("cx", @x + Puyo.RADIUS)
    @circle.attr("cy", @y + Puyo.RADIUS)

  remove: ->
    @circle.remove()

  _render: ->
    circle = Tokopuyo.paper.circle(-Puyo.RADIUS*2, -Puyo.RADIUS*2, Puyo.RADIUS)
    circle.attr("fill", @color)
    circle.attr("stroke", "#422")
    return circle

# Represents a pair of puyo, both in the field and next area.
class Pair
  @N_PUYOS: 2
  @ROT: [[[0, 0], [0, -1]],
         [[0, 0], [1, 0]],
         [[0, 0], [0, 1]],
         [[0, 0], [-1, 0]]]

  @newrot: (rot, dir) ->
    ret = (rot + dir + Pair.ROT.length) % Pair.ROT.length
    ret

  @positions: (c, r, rot) ->
    _.range(Pair.N_PUYOS).map (i) ->
      [c + Pair.ROT[rot][i][0], r + Pair.ROT[rot][i][1]]

  constructor: (x=null, y=null, cols=[]) ->
    @puyos = _.range(Pair.N_PUYOS).map((i) -> new Puyo(null, null, cols[i]))
    @rot = 0
    @move(x, y) if x && y

  move: (x, y) ->
    [@x, @y] = [x, y]

    @puyos.forEach (puyo, i) =>
      puyo.move(@x + Pair.ROT[@rot][i][0] * Puyo.WIDTH,
                @y + Pair.ROT[@rot][i][1] * Puyo.HEIGHT)

  rotate: (dir) ->
    @rot = Pair.newrot(@rot, dir)
    @move(@x, @y)

# Main class. Represents 6x14 play field.
class Field
  @COLS: 6
  @ROWS: 14
  @TOP : Puyo.HEIGHT
  @LEFT: 0
  @WIDTH : Puyo.WIDTH  * @COLS
  @HEIGHT: Puyo.HEIGHT * (@ROWS + 1)
  @RIGHT : @LEFT + @WIDTH
  @BOTTOM: @TOP  + @HEIGHT

  @col2x: (i) -> Field.LEFT + Puyo.WIDTH * i
  @row2y: (j) -> Field.TOP + Puyo.HEIGHT * j

  constructor: ->
    # Render background
    # Note: must be prior to new Current() and new Nexts(),
    # otherwise they will go below background
    Tokopuyo.paper.rect(Field.LEFT, Field.TOP + Puyo.HEIGHT*Pair.N_PUYOS,
                        Field.WIDTH, Field.HEIGHT)
                  .attr("fill", "#888")

    @field = _.range(Field.ROWS).map ->
               _.range(Field.COLS).map ->
                 null
    @state = "normal"

    @nexts = new Nexts
    @current = new Current(@nexts.shift())


  onKeyDown: (code) ->
    switch code
      when 37 #left
        @move(-1)
      when 39 #right
        @move(+1)
      when 40 #down
        @drop()
        @envanish()
      when 90 #z
        @rotate(-1)
      when 88 #x
        @rotate(+1)
      when 82 #r
        @reset()
      when 66 #b
        @back()

  move: (dir) ->
    @current.move(dir)

  rotate: (dir) ->
    @current.rotate(dir)

  reset: () ->
    @field = @field.map (row) ->
               row.map (puyo) ->
                 puyo.remove() if puyo
                 null

  back: () ->

  drop: ->
    return unless @state == "normal"

    poss = @current.positions()
    _.sortBy(_.range(Pair.N_PUYOS), (i) -> -poss[i][1]).forEach (i) =>
      [c, r] = poss[i]
      drop_r = _.find(_.range(Field.ROWS).reverse(), (rr) =>
                 @field[rr][c] == null
      ) || 0
      @field[drop_r][c] = @current.pair.puyos[i]
      @_movePuyo(@current.pair.puyos[i], c, drop_r)

    @current = new Current(@nexts.shift())

  _movePuyo: (puyo, c, r) ->
    puyo.move(Field.col2x(c), Field.row2y(r))

  @VANISH_COUNT: 4
  @FALL_DELAY: 500
  @NEXT_VANISH_DELAY: 500
  envanish: (done=null) ->
    @state = "vanishing"

    # Mark empty cells as already visited
    visited = @field.map (row) ->
                row.map (cell) ->
                  (cell == null) ? true : false
    toVanish = []
    q = [[0, Field.ROWS-1]] # start from bottom left corner
    while (pos = @_nextVisiblePos(visited))
      poss = @_connectedVisiblePuyos(pos[0], pos[1], visited)
      toVanish = toVanish.concat(poss) if poss.length >= Field.VANISH_COUNT

    if _.isEmpty(toVanish)
      @state = "normal"
      done()
    else
      # Remove puyos
      toVanish.forEach (pos) =>
        @field[pos[1]][pos[0]].remove()
        @field[pos[1]][pos[0]] = null

      _.delay(=>
        # Drop puyos
        _.range(Field.ROWS).reverse().forEach (j) =>
          _.range(Field.COLS).forEach (i) =>
            if @field[j][i] == null and (jj = _.find(_.range(j).reverse(), (jj) => @field[jj][i] != null))
              @_movePuyo(@field[jj][i], i, j)
              @field[j][i] = @field[jj][i]
              @field[jj][i] = null

        _.delay(=>
          @envanish(done)
        , Field.NEXT_VANISH_DELAY)
      , Field.FALL_DELAY)

  # Returns a position not visited yet, or return null if there are none.
  # Invisible area (c==0, 1) are not counted.
  _nextVisiblePos: (visited) ->
    # Using try-catch to escape from double loop
    try
      _.range(2, Field.ROWS).forEach (j) ->
        _.range(Field.COLS).forEach (i) ->
          if not visited[j][i]
            throw [i, j]
      return null
    catch pos
      return pos

  # Returns positions of puyos of the same color as (c, r).
  # Invisible area (c==0, 1) are not counted.
  # Destructively updates +visited+.
  @NEIGHBORS: [[+1, 0], [0, +1], [-1, 0], [0, -1]]
  _connectedVisiblePuyos: (c, r, visited) ->
    col = @field[r][c].color
    poss = [[c, r]]
    q = [[c, r]]
    until _.isEmpty(q)
      [i, j] = q.shift()
      visited[j][i] = true
      Field.NEIGHBORS.forEach (dij) =>
        [di, dj] = dij
        [ni, nj] = [i+di, j+dj]
        return unless (0 <= ni < Field.COLS && 2 <= nj < Field.ROWS)
        return if visited[nj][ni]

        if @field[nj][ni].color == col &&
           !poss.some((pos) -> _.isEqual(pos, [ni, nj]))
          poss.push([ni, nj])
          q.push([ni, nj])

    return poss

# Represents next area (N pairs).
class Nexts
  @N_PAIRS: 2
  @LEFT: Field.RIGHT + Puyo.WIDTH
  @TOP: Field.TOP + Puyo.HEIGHT/2

  constructor: ->
    @generator = new PairGenerator16(_.range(Puyo.COLORS.length))
    @pairs = _.range(Nexts.N_PAIRS).map(=> @generator.generatePair())
    @_rearrange()

  shift: ->
    nextPair = @pairs.shift()
    @pairs.push(@generator.generatePair())
    @_rearrange()
    return nextPair

  _rearrange: ->
    @pairs.forEach (pair, i) ->
      x = Nexts.LEFT + Puyo.WIDTH * (i*1.5)
      y = Nexts.TOP
      pair.move(x, y)

# Algorithm to generate list of pairs.
class PairGenerator
  constructor: (colors) ->
    @colors = colors

  generatePair: ->
    cols = @generateColPair()
    new Pair(null, null, cols)

  _generateColPairs: (nPairs) ->
    puyos = []
    perCol = Math.ceil(nPairs*Pair.N_PUYOS / @colors.length)
    @colors.forEach (col) ->
      puyos = puyos.concat(_.range(perCol).map(-> col))
    puyos = puyos.slice(0, nPairs*Pair.N_PUYOS)

    puyos = _.shuffle(puyos)
    # Slice puyos by N_PUYOS to make list of pairs
    return _.range(nPairs).map (i) ->
      _.range(Pair.N_PUYOS).map (j) ->
        puyos[i * Pair.N_PUYOS + j]


# Simulates Windows Puyo-fever(classic)
class PairGenerator16 extends PairGenerator
  constructor: (args...) ->
    super(args...)
    loop
      @list = @_generateColPairs(8)
      break if @_goodStart(@list)

  generateColPair: ->
    if _.isEmpty(@list)
      @list = @_generateColPairs(8)
    return @list.shift()

  # First 2 pairs must contain colors between 2..3
  _goodStart: (list) ->
    nCols = _.uniq(_.flatten(list[0], list[1])).length
    2 <= nCols <= 3

# Simulates AC Puyo-2
class PairGenerator128 extends PairGenerator
  constructor: (args...) ->
    super(args...)
    loop
      @list = @_generateColPairs(128)
      break if @_goodStart(@list)
    @cur = 0

  generateColPair: ->
    ret = @list[@cur]
    @cur = (@cur + 1) % 128
    ret

  # First 3 pairs must contain colors <= 3
  _goodStart: (list) ->
    nCols = _.uniq(_.flatten(list[0], list[1], list[2])).length
    1 <= nCols <= 3

# Represents the current pair.
# Handles validation of moving/rotation.
class Current
  @INITIAL_COL = Field.COLS/2 - 1

  constructor: (pair) ->
    @c = Current.INITIAL_COL
    @r = 0
    @pair = pair
    @pair.move(Field.col2x(@c), Field.row2y(@r))

  move: (dir) ->
    if @_isValid(@c + dir, @r, @pair.rot)
      @c += dir
      @pair.move(Field.col2x(@c), Field.row2y(@r))

  rotate: (dir) ->
    if @_isValid(@c, @r, Pair.newrot(@pair.rot, dir))
      @pair.rotate(dir)
    else
      @move(if @c == 0 then +1 else -1)
      @pair.rotate(dir)

  positions: ->
    Pair.positions(@c, @r, @pair.rot)

  _isValid: (c, r, rot) ->
    _.every Pair.positions(c, r, rot), (pos) ->
      0 <= pos[0] < Field.COLS

# ---

# main

window.Tokopuyo =
  Puyo: Puyo
  Pair: Pair
  Field: Field
  Nexts: Nexts
  PairGenerator: PairGenerator
  PairGenerator16: PairGenerator16
  PairGenerator128: PairGenerator128
  Current: Current
  paper: null
  main: ->
    w = Field.WIDTH*2
    h = Field.HEIGHT
    Tokopuyo.paper = Raphael(10, 50, w, h)

    bg = Tokopuyo.paper.rect(0, 0, w, h)
    bg.attr("fill", "#533")

    field = new Field
    $(window).on "keydown", (e) ->
      field.onKeyDown(e.keyCode)
