{ config, dict, log, even, degToRad, partition, flatten } = require './utils'
pbm = require './ball_model'
assert = require 'assert'


PLAYER_IDS = config.player_ids
BALL_SIZE = config.ball_size
ARENA_SIZE = config.arena_size
BALL_LEVELS = config.ball_levels


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
    {ball_positions, triangles} = @calculateStartPointsAndTriangles()

    random_triangles = @pickRandomTriangles triangles

    @balls = for {x, y} in flatten ball_positions
      new pbm.BallModel genBallId(), pbm.makePlayerBallType(nextPlayerId()), x, y

    @angles = playerIdDict (i) -> 0

    @stored_balls = playerIdDict (i) -> null

  # Picks random triangles to rotate
  pickRandomTriangles: (triangles) ->

    # Calculates if any point of the triangle is already
    # in triangles and returns false if so
    pointNotAlreadyInTriangles = (triangles, triangle) ->
      for rand_triangle in triangles
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
        rand_triangles.push triangle

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

    dist_between_balls = config.dist_between_balls
    dist_components = {dx: dist_between_balls / 2, dy: Math.sin(degToRad(60)) * dist_between_balls}
    center_point = { x: ARENA_SIZE.x/2, y: ARENA_SIZE.y/2 }

    triangles = []
    ball_positions = []
    rows = BALL_LEVELS * 2 - 1

    for row in [0...rows]
      ball_positions[row] = []
      cols = ballsForRow row
      rows_from_center = rowsFromCenter row
      for col in [0..cols]
        # calculate positions
        half_col = Math.floor(col / 2)
        ball_positions[row][col] =
          x : center_point.x +
              (col - half_col) * dist_between_balls +
              if even cols
                dist_components.dx
              else
                0
          y : Math.round (center_point.y + dist_components.dy * (row - Math.floor(rows / 2)))

        # calculate triangles
        triangles.push(
          [{ x : row,    y : half_col }
          {x : row + 1, y : half_col + 1}
          if even(col)
            { x : row + 1, y : half_col}
          else
            {x : row, y : half_col + 1}
          ])

    ball_positions: ball_positions
    triangles: triangles


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

