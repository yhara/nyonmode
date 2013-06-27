#= require tokopuyos

Tokopuyo.paper = 
  circle: ->
    return attr: ->

describe "Puyo", ->
  it "has color", ->
    (new Tokopuyo.Puyo).color.should.be.a("string")

  it "can move", ->
    puyo = (new Tokopuyo.Puyo)
    puyo.move(1, 2)
    puyo.x.should.equal(1)
    puyo.y.should.equal(2)

