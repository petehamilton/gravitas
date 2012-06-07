{ config, dict, log, even, degToRad, partition, flatten, assert, negativeMod } = require './utils'
pbm = require './ball_model'
assert = require 'assert'


PLAYER_IDS = config.player_ids
BALL_SIZE = config.ball_size
ARENA_SIZE = config.arena_size
BALL_LEVELS = config.ball_levels

DIRECTIONS =
  LEFT: 0
  RIGHT: 1



next_ball_id = 0
genBallId = -> next_ball_id++

cur_player_index = 0
# Loops around player Id's
nextPlayerId = ->
  tmp = PLAYER_IDS[cur_player_index++]
  cur_player_index %= PLAYER_IDS.length
  tmp

# Creates an object mapping from player ID to value created by `fn`.
playerIdDict = (fn) ->
  dict ([i, fn(i)] for i in PLAYER_IDS)


class @ArenaModel

  constructor: ->
    { ball_positions, triangles } = @calculateStartPointsAndTriangles()


    random_triangles = @pickRandomTriangles triangles

    @balls = for {x, y} in flatten ball_positions
      new pbm.BallModel genBallId(), pbm.makePlayerBallType(nextPlayerId()), x, y

    @rotateTriangles random_triangles, ball_positions

    @angles = playerIdDict (i) -> 0

    @stored_balls = playerIdDict (i) -> null


  # Picks random triangles to rotate
  pickRandomTriangles: (triangles) ->

    # Calculates if any point of the triangle is already
    # in triangles and returns false if so
    pointNotAlreadyInTriangles = (triangles, triangle) ->
      for {triangle: rand_triangle} in triangles
        for point in triangle
          {x: x_p, y: y_p} = point
          for {x: x_r, y: y_r} in rand_triangle
            if( x_p == x_r and y_p == y_r )
              return false

      true


    temp_triangles = triangles.slice 0
    rand_triangles = []

    while temp_triangles.length != 0
      index = Math.floor(Math.random() * (temp_triangles.length - 1))
      triangle = temp_triangles[index]
      temp_triangles.splice(index, 1)
      if pointNotAlreadyInTriangles(rand_triangles, triangle)
        rand_triangles.push
          triangle: triangle
          direction: Math.round Math.random()

    rand_triangles


  # Calculates starting points for all the balls
  # Triangles are in a data structure such that
  # triangle = [
  #   {x : 0, y : 0},
  #   {x : 0, y : 1},
  #   {x : 1, y : 1},
  # ]
  # where a, b, c are the corners
  calculateStartPointsAndTriangles: ->

    # Calculates how many rows from the center a given row is
    rowsFromCenter = (row) ->
      Math.abs(BALL_LEVELS - 1 - row)


    # Calculates the number of balls for a given row
    ballsForRow = (row) ->
      max_index = BALL_LEVELS - 1
      offset = rowsFromCenter row
      max_index - offset + BALL_LEVELS


    ballRows = ->
      BALL_LEVELS * 2 - 1


    triangleRows = ->
      ballRows() - 1


    trianglesForRow = (row) ->
      ballsForRow(row) - 1  + ballsForRow(row + 1) - 1


    # Calculates the points for a triangle with two points
    # at the bottom and one at the top
    calculateTrianglePoints = (row, col, latterhalf = false) ->
      half_col = Math.floor(col / 2)

      [
        if latterhalf
          { x : row, y : half_col + 1 }
        else
          { x : row, y: half_col }
        { x : row + 1, y : half_col + 1 }
        { x : row + 1, y : half_col }
      ]


    # Calculates the points for a triangle with two points
    # at the top and one at the bottom
    calculateUpsideDownTrianglePoints = (row, col, latterhalf = false) ->
      half_col = Math.floor(col / 2)
      [
        { x: row,     y : half_col }
        { x: row,     y : half_col + 1 }
        if latterhalf
          { x: row + 1, y : half_col }
        else
          { x: row + 1, y : half_col + 1}
      ]


    dist_between_balls = config.dist_between_balls
    dist_components = {dx: dist_between_balls / 2, dy: Math.sin(degToRad(60)) * dist_between_balls}
    center_point = { x: ARENA_SIZE.x/2, y: ARENA_SIZE.y/2 }

    ball_positions = []
    rows = ballRows()

    for row in [0...rows]
      ball_positions[row] = []
      cols = ballsForRow row
      rows_from_center = rowsFromCenter row

      for col in [0...cols]
        ball_positions[row][col] =
          x : center_point.x +
              (col - Math.floor(cols / 2)) * dist_between_balls +
              if even cols
                dist_components.dx
              else
                0
          y : Math.round (center_point.y + dist_components.dy * (row - Math.floor(rows / 2)))


    triangles = []
    rows = triangleRows()
    half_rows = Math.floor(rows / 2)

    for row in [0...rows]
      cols = trianglesForRow row
      for col in [0...cols]
        half_col = Math.floor(col / 2)
        triangles.push (
          if row < half_rows
            if even col
              calculateTrianglePoints row, col
            else
              calculateUpsideDownTrianglePoints row, col
          else
            if even col
              calculateUpsideDownTrianglePoints row, col, true
            else
              calculateTrianglePoints row, col, true
        )

    ball_positions: ball_positions
    triangles: triangles


  rotateTriangles: (triangles, ball_positions) ->

    # Finds the ball in @balls for a given point in the form
    # {x: ..., y: ...}
    # TODO: Is there a quicker way than looping through?
    # Can we do some sort of dictionary lookup?
    findBall = (x, y) =>
      for ball in @balls
        { x: x_b, y: y_b } = ball
        if x == x_b and y == y_b
          return ball
      null

    triangle_points = 3
    for {triangle, direction} in triangles
      for index in [0...triangle_points]
        { x, y } = triangle[index]
        { x, y } = ball_positions[x][y]
        ball = findBall(x, y)
        assert(ball, "Error cannot find plasma ball for triangle point")
        if direction == DIRECTIONS.LEFT
          { x: x_new, y: y_new } = triangle[negativeMod(index - 1, triangle_points)]
        else
          { x: x_new, y: y_new } = triangle[negativeMod(index + 1, triangle_points)]
        ball.x = x_new
        ball.y = y_new


  setAngle: (player, angle) ->
    @angles[player] = angle


  pull: (player, x, y, pullCallback) ->
    # TODO remove X, Y only allow pulling balls in line
    r = config.pull_radius

    angle = @angles[player]

    # Find the balls that were selected by the pull
    [selected, others] = partition @balls, (b, i) ->
      Math.abs(x - b.x) < r and Math.abs(y - b.y) < r

    assert.ok(selected.length in [0,1], "not more than one ball should be selected in a pull")

    if selected.length
      b = selected[0]

      # Remove pulled ball from available balls
      log "player #{player} pulled ball #{b.id} at", [b.x, b.y]
      pullCallback b

      @stored_balls[player] = b

      # All other balls stay
      @balls = others


  shoot: (player, shotCallback) ->
    angle = @angles[player]
    b = @stored_balls[player]
    if not b
      log "player #{player} tries to shoot, but has no ball"
    else
      log "player #{player} shoots ball #{b.id} of kind #{b.type.kind} with angle #{angle}"
      shotCallback b, angle
      delete @stored_balls[player]

