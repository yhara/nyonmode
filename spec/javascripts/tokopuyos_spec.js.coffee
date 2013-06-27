#= require tokopuyos

# Note: create Null Object of raphael.js
Tokopuyo.paper =
  circle: ->
    return attr: ->

_.extend(this, Tokopuyo)

describe "Puyo", ->
  it "has color", ->
    expect((new Puyo).color).to.a("string")

  it "can move", ->
    puyo = (new Puyo)
    puyo.move(1, 2)
    expect(puyo.x).to.equal(1)
    expect(puyo.y).to.equal(2)

describe "Pair", ->
  beforeEach ->
    @pair = (new Pair)

  it "has Puyos", ->
    expect(@pair.puyos[0]).to.instanceof(Puyo)
    expect(@pair.puyos[1]).to.instanceof(Puyo)

  it "has rot", ->
    expect(@pair.rot).to.equal(0)

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

#    it "drops belowmost puyo first", ->
#      @field.drop()
#      expect(@field.field[Field.ROWS-1][Current.INITIAL_COL]).not.to.null
