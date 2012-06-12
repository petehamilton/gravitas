{ config, dict, log, even, degToRad, partition, flatten, assert, negativeMod, radToDeg } = require './utils'
pbm = require './ball_model'
plm = require './player_model'
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


class @ArenaModel

  constructor: ->
    @players = (new plm.PlayerModel(i, config.player_colours[i]) for i in PLAYER_IDS)
    log @players
    @ball_positions  = @calculateStartPoints(config.dist_between_balls, ARENA_SIZE, BALL_LEVELS)
    @triangles       = @calculateTriangles(BALL_LEVELS)

    @balls = for {x, y} in flatten @ball_positions
      new pbm.BallModel genBallId(), pbm.makePlayerBallType(nextPlayerId()), x, y

    # Holds all the active balls that players have shot.
    @active_balls = []


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
  rowsFromCenter: (ball_levels, row) ->
    Math.abs(ball_levels - 1 - row)


  # Calculates the number of balls for a given row
  ballsForRow: (ball_levels, row) ->
    max_index = ball_levels - 1
    offset = @rowsFromCenter ball_levels, row
    max_index - offset + ball_levels


  # Calculates the number of rows of the plasma ball structure
  ballRows: (ball_levels) ->
    ball_levels * 2 - 1


  # Calculates starting points for all the balls
  calculateStartPoints: (dist_between_balls, arena_size, ball_levels)->
    # dist_between_balls = config.dist_between_balls
    dist_components = {dx: dist_between_balls / 2, dy: Math.sin(degToRad(60)) * dist_between_balls}
    center_point = { x: arena_size.x/2, y: arena_size.y/2 }

    ball_positions = []
    rows = @ballRows ball_levels
    for row in [0...rows]
      ball_positions[row] = []
      cols = @ballsForRow ball_levels, row
      rows_from_center = @rowsFromCenter ball_levels, row

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
  calculateTriangles: (ball_levels) ->

    triangleRows = (ball_levels) =>
      @ballRows(ball_levels) - 1


    trianglesForRow = (ball_levels, row) =>
      @ballsForRow(ball_levels, row) - 1  + @ballsForRow(ball_levels, row + 1) - 1


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
    player.turret_angle = angle


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
  pull: (player, x, y, pullCallback, validPullSoundCallback, invalidPullSoundCallback) ->
    # Find the balls that were selected by the pull
    r = config.pull_radius
    [selected, others] = partition @balls, (b, i) ->
      Math.abs(x - b.x) < r and Math.abs(y - b.y) < r

    assert.ok(selected.length in [0,1], "not more than one ball should be selected in a pull")

    if selected.length
      ball = selected[0]

      is_powerup = ball.type.kind == config.ball_kinds.powerup

      # TODO: Remove Later when using collision with turret

      if is_powerup or ball.type.player_id == player.id
        validPullSoundCallback()

        turret_center = config.player_centers[player.id]

        log "player #{player} pulled ball #{ball.id} at", [ball.x, ball.y]


        @balls = others # All other balls stay

        pullCallback ball, turret_center.x, turret_center.y, is_powerup

        unless is_powerup
          player.stored_balls = [ball]


      else
        invalidPullSoundCallback()


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
    distance = 600

    angle = player.turret_angle

    ball = player.stored_balls[0]

    unless ball
      log "player #{player} tries to shoot, but has no ball"
    else
      log "player #{player} shoots ball #{ball.id} of kind #{ball.type.kind} with angle #{angle}"
      { x: oldX, y: oldY } = ball
      radius = Math.max(config.arena_size.x, config.arena_size.y) * 1.42
      target =
        x: oldX + Math.cos(degToRad(angle)) * radius
        y: oldY + Math.sin(degToRad(angle)) * radius

      # Removes element at index 0
      player.stored_balls.splice(0, 1)
      @active_balls.push ball

      shotCallback ball, target.x, target.y

  # Gives a powerup to a player
  #
  # player              : The player who has received the powerup
  # powerup_type        : The type of powerup, types defined in config
  # activateCallback    : Called when the powerup is activated
  # deactivateCallback  : Called when the powerup is deactivated
  setPowerup: (player, powerup_type, activateCallback, deactivateCallback) ->
    log "player #{player} has collected a #{powerup_type} powerup"
    player.powerup = switch powerup_type
      when config.powerup_kinds.shield
        new spm.ShieldPowerupModel activateCallback, deactivateCallback

  # Removes ball from @active_balls if it exists
  remove: (ball) ->
    index = @active_balls.indexOf(ball)
    unless index == -1
      @active_balls.splice(index, 1)

  # Activates a player's powerup.
  # If they don't have one, does nothing
  #
  # player : The player using their powerup
  usePowerup: (player) ->
    unless player.powerup
      log "player #{player} tries to use their powerup, but doesn't have one!"
    else if player.powerup.activated
      log "player #{player} has already activated their powerup"
    else
      log "player #{player} uses their powerup"
      player.powerup.activate()


  # Checks for collisions between each player and the active balls
  # collisionCallback : Called whenever a collision is detected
  # Removes balls from active_balls when they go out of the arena bounds
  processBallPositions: (collisionCallback) ->
    inBounds = (x, y) ->
      0 <= x <= ARENA_SIZE.x and 0 <= y <= ARENA_SIZE.y

    processCollision = (ball, player) =>
      collision_point =
        x: player.center.x + Math.cos(angle) * contact_radius
        y: player.center.y + Math.sin(angle) * contact_radius

      collisionCallback(player, ball, collision_point.x, collision_point.y)

    for ball in @active_balls
      unless inBounds(ball.x, ball.y)
        @remove(ball)

      for player in @players
        contact_radius = player.health * config.shield_radius
        dx = ball.x - player.center.x
        dy = ball.y - player.center.y

        distance = Math.sqrt (dx * dx + dy * dy)
        angle = Math.atan2(dy, dx)

        if distance < contact_radius
          processCollision(ball, player)



  # Handles the collision between a player's shield and a ball
  #
  # player          : The player in the collision
  # ball_model      : The ball which has collided with the player
  # x               : The x coord of impact
  # y               : The y coord of impact
  # handledCallback : Called once the collision has been handled
  handleCollision: (player, ball_model, x, y, handledCallback) ->
    if ball_model.floating and ball_model.type.player_id != player.id
      player.health -= 0.1
      ball_model.floating = false
      ball_model.stopAnimation()
      ball_model.x = x
      ball_model.y = y
      handledCallback() if handledCallback
      @remove(ball_model)
#
