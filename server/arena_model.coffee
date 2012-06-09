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
    @ball_positions  = @calculateStartPoints()
    @triangles       = @calculateTriangles()
    @ball_neighbours = @calculateBallNeighbours()

    @balls = for {x, y} in flatten @ball_positions
      new pbm.BallModel genBallId(), pbm.makePlayerBallType(nextPlayerId()), x, y

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


  # Calculates how many rows from the center a given row
  # in the plasma ball structure is
  rowsFromCenter: (row) ->
    Math.abs(BALL_LEVELS - 1 - row)


  # Calculates the number of balls for a given row
  ballsForRow: (row) ->
    max_index = BALL_LEVELS - 1
    offset = @rowsFromCenter row
    max_index - offset + BALL_LEVELS


  # Calculates the number of rows of the plasma ball structure
  ballRows: ->
    BALL_LEVELS * 2 - 1


  # Calculates starting points for all the balls
  calculateStartPoints: ->

    dist_between_balls = config.dist_between_balls
    dist_components = {dx: dist_between_balls / 2, dy: Math.sin(degToRad(60)) * dist_between_balls}
    center_point = { x: ARENA_SIZE.x/2, y: ARENA_SIZE.y/2 }

    ball_positions = []
    rows = @ballRows()

    for row in [0...rows]
      ball_positions[row] = []
      cols = @ballsForRow row
      rows_from_center = @rowsFromCenter row

      for col in [0...cols]
        ball_positions[row][col] =
          x : center_point.x +
              (col - Math.floor(cols / 2)) * dist_between_balls +
              if even cols
                dist_components.dx
              else
                0
          y : Math.round (center_point.y + dist_components.dy * (row - Math.floor(rows / 2)))

    ball_positions


  # Calculates balls neighbours
  # Must be called after calculateTrainglePoints
  calculateBallNeighbours: ->

    # Inserts into list only if x_n and x_y are not
    # already in the neighbours list
    insertNeighbours = (x, y, x_n, y_n, list) ->
      unless list[x][y]?
        list[x][y] = []

      for { x: x_p, y: y_p } in list[x][y]
        if x_p == x_n and y_p == y_n
          return

      list[x][y].push { x: x_n, y: y_n }


    # setup
    ball_neighbours = []
    for row in [0...@ballRows()]
      ball_neighbours[row] = []

    for triangle in @triangles
      for { x: x_p, y: y_p } in triangle
        for { x: x_n, y: y_n } in triangle
          if x_n != x_p or y_n != y_p
            insertNeighbours(x_p, y_p, x_n, y_n, ball_neighbours)


    ball_neighbours



  # Calculates all possible triangles in the ball structure.
  # triangles are of the format:
  # triangle = [
  #   {x : 0, y : 0},
  #   {x : 0, y : 1},
  #   {x : 1, y : 1},
  # ]
  # where a, b, c are the corners
  calculateTriangles: ->

    triangleRows = =>
      @ballRows() - 1


    trianglesForRow = (row) =>
      @ballsForRow(row) - 1  + @ballsForRow(row + 1) - 1


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

    triangles


  # Rotates triangles randomly. If there isn't a ball in the center a new
  # one will be spawned
  rotateTriangles: ->

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


    random_triangles = @pickRandomTriangles @triangles
    triangle_points = 3
    balls_to_move = []
    for {triangle, direction} in random_triangles
      for index in [0...triangle_points]
        { x, y } = triangle[index]
        { x, y } = @ball_positions[x][y]
        ball = findBall(x, y)
        # assert(ball, "Error cannot find plasma ball for triangle point")
        if ball?
          if direction == DIRECTIONS.LEFT
            { x: x_new, y: y_new } = triangle[negativeMod(index - 1, triangle_points)]
            { x: x_new, y: y_new } = @ball_positions[x_new][y_new]
          else
            { x: x_new, y: y_new } = triangle[negativeMod(index + 1, triangle_points)]
            { x: x_new, y: y_new } = @ball_positions[x_new][y_new]
          balls_to_move.push
            ball: ball
            x: x_new
            y: y_new

    # console.log "Balls to move", balls_to_move
    for { ball, x, y } in balls_to_move
      ball.x = x
      ball.y = y

    center_point = { x: ARENA_SIZE.x/2, y: ARENA_SIZE.y/2 }
    unless findBall(center_point.x, center_point.y)?
      console.log "Spawning new ball"
      @spawnNewBall(center_point.x, center_point.y)


  # Spawns a new ball at the given coordinates
  spawnNewBall: (x, y) ->
    @balls.push(new pbm.BallModel(genBallId(), pbm.makePlayerBallType(nextPlayerId()), x, y))

  # x and y are relative to the area. Transposes them relative
  # to grid layout, then chooses a ball to move
  replaceBall: (x, y) ->

    # Finds ball in ball_positions
    findBall = (x, y) =>
      for row in [0...@ball_positions.length]
        for col in [0...@ball_positions[row].length]
          { x: x_b, y: y_b } = @ball_positions[row][col]
          if x == x_b and y == y_b
            return { x: row, y: col }
      return null

    transposed = findBall(x, y)
    assert(transposed, "Error finding ball to replace pulled ball")

    neighbours = @ball_neighbours[transposed.x][transposed.y]
    neighbour = Math.floor(Math.random() * (neighbours.length - 1))
    neighbour.x = x
    neighbour.y = y

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

