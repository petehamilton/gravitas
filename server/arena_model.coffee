{ config, dict, log, even, degToRad, partition, flatten, assert, negativeMod } = require './utils'
pbm = require './ball_model'
spm = require './shield_powerup_model'
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

    @balls = for {x, y} in flatten @ball_positions
      new pbm.BallModel genBallId(), pbm.makePlayerBallType(nextPlayerId()), x, y

    @angles = playerIdDict (i) -> 0

    @stored_balls = playerIdDict (i) -> null

    @powerups = playerIdDict (i) -> null


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
    random = Math.random()
    if random <= config.powerup_probability
      # TODO Don't know if this gives an even split?
      powerup_type = Math.round(Math.random() * (config.powerup_count - 1))
      console.log "Creating powerup of kind", powerup_type
      type = pbm.makePowerupBallType(powerup_type)
    else
      type = pbm.makePlayerBallType(nextPlayerId())

    @balls.push(new pbm.BallModel(genBallId(), type, x, y))


  setAngle: (player, angle) ->
    @angles[player] = angle


  # Responsible for handling a player pulling a ball.
  # 
  # works out which ball needs to be pulled, then calculates where to pull it
  # to (basically the player's corner). Finally calls the pullCallback function
  # with the pulled ball and the target coords as parameters
  #
  # TODO: activate/deactivate to be removed soon in favour of turret-detection
  # TODO: Only allow balls to be pulled in straight line
  #
  # player        : player who is pulling
  # x, y          : crosshair coords
  # pullCallback  : passed (pulled_ball, target_x, target_y), called once 
  #                 coords calculated
  #
  pull: (player, x, y, pullCallback, activatePowerupCallback, deactivatePowerupCallback) ->
    # Find the balls that were selected by the pull
    r = config.pull_radius
    [selected, others] = partition @balls, (b, i) ->
      Math.abs(x - b.x) < r and Math.abs(y - b.y) < r

    assert.ok(selected.length in [0,1], "not more than one ball should be selected in a pull")

    if selected.length
      b = selected[0]

      # TODO: Remove Later when using collision with turret
      if b.type.kind == config.ball_kinds.powerup
        @setPowerup(player, b.type.powerup_kind, activatePowerupCallback, deactivatePowerupCallback)

      center = config.player_centers[player]

      log "player #{player} pulled ball #{b.id} at", [b.x, b.y]

      @stored_balls[player] = b
      @balls = others # All other balls stay

      pullCallback b, center.x, center.y


  # Responsible for handling a player shooting their ball. Calculates ball 
  # trajectory and then runs a callback function with target & ball params
  # Does nothing if the player doesn't have any balls
  #
  # player: player to shoot from
  # shotCallback: passed (shot_ball, target_x, target_y)
  #
  # 1. Identifies a target point ~900px away from the current position 
  #    (900 guaruntees it will go off screen).
  # 2. Calculates the target x and y coordinates
  # 3. Deletes the ball from the player's balls
  # 4. Calls the callback function, passing it the ball model and target coords
  shoot: (player, shotCallback) ->
    #TODO, work out distance to nearest object?
    # 900 will mean balls always shoot at same speed
    distance = 900

    angle = @angles[player]

    b = @stored_balls[player]
    if not b
      log "player #{player} tries to shoot, but has no ball"
    else
      log "player #{player} shoots ball #{b.id} of kind #{b.type.kind} with angle #{angle}"
      {x: oldX, y: oldY} = b
      radius = Math.max(config.arena_size.x, config.arena_size.y) * 1.42
      targetx = oldX + Math.cos(degToRad(angle)) * radius
      targety = oldY + Math.sin(degToRad(angle)) * radius
      delete @stored_balls[player]

      shotCallback b, targetx, targety


  # Gives a powerup to a player
  #
  # player              : The player who has received the powerup
  # powerup_type        : The type of powerup, types defined in config
  # activateCallback    : Called when the powerup is activated
  # deactivateCallback  : Called when the powerup is deactivated
  setPowerup: (player, powerup_type, activateCallback, deactivateCallback) ->
    log "player #{player} has collected a #{powerup_type} powerup"
    powerup = switch powerup_type
      when config.powerup_kinds.shield
        new spm.ShieldPowerupModel player, activateCallback, deactivateCallback

    @powerups[player] = powerup


  # Activates a player's powerup.
  # If they don't have one, does nothing
  #
  # player : The player using their powerup
  usePowerup: (player) ->
    p = @powerups[player]
    console.log p
    if not p
      log "player #{player} tries to use their powerup, but doesn't have one!"
    else if p.activated
      log "player #{player} has already activated their powerup"
    else
      log "player #{player} uses their powerup"
      p.activate()
