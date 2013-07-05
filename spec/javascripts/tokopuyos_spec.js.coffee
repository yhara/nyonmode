#= require tokopuyos

# Import classes
_.extend(this, Tokopuyo)

# Note: create Null Object of raphael.js
Tokopuyo.paper =
  circle: ->
    attr: ->
    remove: ->

# Override constants for test
_.extend Field,
  VANISH_COUNT: 4
  FALL_DELAY: 0
  NEXT_VANISH_DELAY: 0

describe "Puyo", ->
  it "has color", ->
    expect((new Puyo).color).to.a("string")

  it "can move", ->
    puyo = (new Puyo)
    puyo.move(1, 2)
    expect(puyo.x).to.equal(1)
    expect(puyo.y).to.equal(2)

  describe ".new", ->
    it "can take colorIdx", ->
      puyos = _.range(10).map () ->
        new Puyo(-1, -1, 0)
      puyos.forEach (puyo) ->
        expect(puyo.color).to.equal(puyos[0].color)

describe "Pair", ->
  beforeEach ->
    @pair = (new Pair)

  it "has Puyos", ->
    expect(@pair.puyos[0]).to.instanceof(Puyo)
    expect(@pair.puyos[1]).to.instanceof(Puyo)

  it "has rot", ->
    expect(@pair.rot).to.equal(0)

  describe ".newrot", ->
    it "should wrap around", ->
      expect(Pair.newrot(0, -1)).to.equal(Pair.ROT.length-1)
      expect(Pair.newrot(Pair.ROT.length-1, +1)).to.equal(0)

  describe "#move", ->
    it "changes @x, @y", ->
      @pair.move(1, 2)
      expect(@pair.x).to.equal(1)
      expect(@pair.y).to.equal(2)

    it "moves puyo", ->
      origX = @pair.puyos[0].x
      @pair.move(1, 2)
      expect(@pair.puyos[0].x).not.to.equal(origX)

  describe "#rotate", ->
    it "changes @rot", ->
      @pair.rotate(+1)
      expect(@pair.rot).to.equal(1)

    it "moves puyo", ->
      # Note: puyos[0] does not move with rotation
      origX = @pair.puyos[1].x
      @pair.rotate(+1)
      expect(@pair.puyos[1].x).not.to.equal(origX)

describe "Field", ->
  beforeEach ->
    @field = (new Field)

  it "has array of array", ->
    expect(@field.field.length).to.equal(Field.ROWS)
    expect(@field.field[0].length).to.equal(Field.COLS)

  describe "#drop", ->
    it "fills some cells", ->
      @field.drop()
      expect(@field.field[Field.ROWS-1][Current.INITIAL_COL]).not.to.null

    it "drops belowmost puyo first", ->
      # Rotate twice to make it upside-down
      @field.rotate(+1)
      @field.rotate(+1)
      puyo1 = @field.current.pair.puyos[1]
      @field.drop()

      expect(@field.field[Field.ROWS-1][Current.INITIAL_COL])
        .to.equal(puyo1)

  describe "#envanish", ->
    it "removes connected puyos", (done) ->
      _.range(4).forEach (i) =>
        @field.field[Field.ROWS-1][i] = new Puyo(-1, -1, 0)

      @field.envanish()

      setTimeout(() =>
        expect(@field.state).to.equal("normal")
        _.range(4).forEach (i) =>
          expect(@field.field[Field.ROWS-1][i]).to.null
        done()
      , 40)

describe "Nexts", ->
  beforeEach ->
    @nexts = new Nexts

  it "has pairs", ->
    expect(@nexts.pairs[1]).to.instanceof(Pair)

describe "PairGenerator", ->
  beforeEach ->
    @cols = [0, 1, 2, 3]
    @gen = new PairGenerator(@cols)

  it "generate pairs of colors", ->
    pairs = @gen._generateColPairs(4)
    expect(pairs.length).to.equal(4)
    expect(pairs[0].length).to.equal(Pair.N_PUYOS)

describe "PairGenerator16", ->
  beforeEach ->
    @cols = [0, 1, 2, 3]
    @gen = new PairGenerator16(@cols)

  it "generate pair of colors", ->
    pair = @gen.generateColPair()
    expect(pair.length).to.equal(Pair.N_PUYOS)
    pair.forEach (col) =>
      expect(@cols).to.include(col)

describe "PairGenerator128", ->
  beforeEach ->
    @cols = [0, 1, 2, 3]
    @gen = new PairGenerator128(@cols)

  it "generate pair of colors", ->
    pair = @gen.generateColPair()
    expect(pair.length).to.equal(Pair.N_PUYOS)
    pair.forEach (col) =>
      expect(@cols).to.include(col)

describe "Current", ->
  beforeEach ->
    @pair = new Pair
    @current = new Current(@pair)

  it "has col and row", ->
    expect(@current.c).to.equal(Current.INITIAL_COL)
    expect(@current.r).to.equal(0)

  describe "move", ->
    it "changes position of @pair", ->
      origX = @pair.x
      @current.move(+1)
      expect(@pair.x).not.to.equal(origX)

    it "validates new position", ->
      origX = @pair.x
      @current.c = 0
      @current.move(-1)
      expect(@pair.x).to.equal(origX)

  describe "rotate", ->
    it "changes position of puyo", ->
      origX = @pair.puyos[1].x
      @current.rotate(+1)
      expect(@pair.puyos[1].x).not.to.equal(origX)

    it "moves pair if needed (left)", ->
      origX = @pair.x
      @current.c = 0
      @current.rotate(-1)
      expect(@current.c).to.equal(1)
      expect(@pair.x).not.to.equal(origX)

    it "moves pair if needed (right)", ->
      @current.c = Field.COLS-1
      @current.rotate(+1)
      expect(@current.c).to.equal(Field.COLS-2)

  describe "positions", ->
    it "returns current col/srows of puyos", ->
      poss = @current.positions()
      expect(poss.length).to.equal(Pair.N_PUYOS)
      expect(poss[0].length).to.equal(2)

