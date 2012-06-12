{ ArenaModel } = require './arena_model'

chai = require 'chai'
{ expect } = chai
chai.should()

arena = new ArenaModel()

describe "Triangle layout", ->
  describe 'layout correct', ->
    dist_between_balls = 60
    arena_size =
      x: 600
      y: 600

    it "has the right number of rows for two levels", ->
      ball_levels = 2
      arena.calculateStartPoints(dist_between_balls, arena_size, ball_levels).should.deep.equal [
        [ { x: 270, y: 248 }, { x: 330, y: 248 } ],
        [ { x: 240, y: 300 }, { x: 300, y: 300 }, { x: 360, y: 300 } ],
        [ { x: 270, y: 352 }, { x: 330, y: 352 } ]
      ]

    it "has the right number of rows for three levels", ->
      ball_levels = 3
      arena.calculateStartPoints(dist_between_balls, arena_size, ball_levels).should.deep.equal [
        [
          { x: 240, y: 196 },
          { x: 300, y: 196 },
          { x: 360, y: 196 }
        ],
        [
          { x: 210, y: 248 },
          { x: 270, y: 248 },
          { x: 330, y: 248 },
          { x: 390, y: 248 }
        ],
        [
          { x: 180, y: 300 },
          { x: 240, y: 300 },
          { x: 300, y: 300 },
          { x: 360, y: 300 },
          { x: 420, y: 300 }
        ],
        [
          { x: 210, y: 352 },
          { x: 270, y: 352 },
          { x: 330, y: 352 },
          { x: 390, y: 352 }
        ],
        [
          { x: 240, y: 404 },
          { x: 300, y: 404 },
          { x: 360, y: 404 }
        ]
      ]

  describe "correct triangle points", ->
    it "has the right balls per triangle for two levels", ->
      ball_levels = 2
      arena.calculateTriangles(ball_levels).should.deep.equal [
        [ { x: 0, y: 0 }, { x: 1, y: 1 }, { x: 1, y: 0 } ],
        [ { x: 0, y: 0 }, { x: 0, y: 1 }, { x: 1, y: 1 } ],
        [ { x: 0, y: 1 }, { x: 1, y: 2 }, { x: 1, y: 1 } ],
        [ { x: 1, y: 0 }, { x: 1, y: 1 }, { x: 2, y: 0 } ],
        [ { x: 1, y: 1 }, { x: 2, y: 1 }, { x: 2, y: 0 } ],
        [ { x: 1, y: 1 }, { x: 1, y: 2 }, { x: 2, y: 1 } ]
      ]

    it "has the right balls per triangle for three levels", ->
      ball_levels = 3
      arena.calculateTriangles(ball_levels).should.deep.equal [
        [ { x: 0, y: 0 }, { x: 1, y: 1 }, { x: 1, y: 0 } ],
        [ { x: 0, y: 0 }, { x: 0, y: 1 }, { x: 1, y: 1 } ],
        [ { x: 0, y: 1 }, { x: 1, y: 2 }, { x: 1, y: 1 } ],
        [ { x: 0, y: 1 }, { x: 0, y: 2 }, { x: 1, y: 2 } ],
        [ { x: 0, y: 2 }, { x: 1, y: 3 }, { x: 1, y: 2 } ],
        [ { x: 1, y: 0 }, { x: 2, y: 1 }, { x: 2, y: 0 } ],
        [ { x: 1, y: 0 }, { x: 1, y: 1 }, { x: 2, y: 1 } ],
        [ { x: 1, y: 1 }, { x: 2, y: 2 }, { x: 2, y: 1 } ],
        [ { x: 1, y: 1 }, { x: 1, y: 2 }, { x: 2, y: 2 } ],
        [ { x: 1, y: 2 }, { x: 2, y: 3 }, { x: 2, y: 2 } ],
        [ { x: 1, y: 2 }, { x: 1, y: 3 }, { x: 2, y: 3 } ],
        [ { x: 1, y: 3 }, { x: 2, y: 4 }, { x: 2, y: 3 } ],
        [ { x: 2, y: 0 }, { x: 2, y: 1 }, { x: 3, y: 0 } ],
        [ { x: 2, y: 1 }, { x: 3, y: 1 }, { x: 3, y: 0 } ],
        [ { x: 2, y: 1 }, { x: 2, y: 2 }, { x: 3, y: 1 } ],
        [ { x: 2, y: 2 }, { x: 3, y: 2 }, { x: 3, y: 1 } ],
        [ { x: 2, y: 2 }, { x: 2, y: 3 }, { x: 3, y: 2 } ],
        [ { x: 2, y: 3 }, { x: 3, y: 3 }, { x: 3, y: 2 } ],
        [ { x: 2, y: 3 }, { x: 2, y: 4 }, { x: 3, y: 3 } ],
        [ { x: 3, y: 0 }, { x: 3, y: 1 }, { x: 4, y: 0 } ],
        [ { x: 3, y: 1 }, { x: 4, y: 1 }, { x: 4, y: 0 } ],
        [ { x: 3, y: 1 }, { x: 3, y: 2 }, { x: 4, y: 1 } ],
        [ { x: 3, y: 2 }, { x: 4, y: 2 }, { x: 4, y: 1 } ],
        [ { x: 3, y: 2 }, { x: 3, y: 3 }, { x: 4, y: 2 } ]
      ]
