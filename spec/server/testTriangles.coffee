{ ArenaModel } = require '../../server/arena_model'

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

  describe "random triangles do not overlap points", ->
    it "checks there are no shared points in random triangles, this test is non deterministic", ->
      check_points_dont_overlap = (triangles, point) ->
        triangleEquals = (triangle1, triangle2) ->
          for i in [0...triangle1.length]
            { x: x1, y: y1 } = triangle1[i]
            { x: x2, y: y2 } = triangle2[i]
            if x1 != x2 or y1 != y2
              return false
          return true

        for {triangle: rand_triangle} in triangles
          unless triangleEquals(triangle, rand_triangle)
            for point in triangle
              {x: x_p, y: y_p} = point
              for {x: x_r, y: y_r} in rand_triangle
                if( x_p == x_r and y_p == y_r )
                  return false
        true


      ball_levels = 3
      triangles = arena.calculateTriangles(ball_levels)
      random_triangles = arena.pickRandomTriangles(triangles)
      for triangle in random_triangles
        check_points_dont_overlap(random_triangles, triangle).should.be.true
