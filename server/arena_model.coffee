{ dict, log, even, degToRad, roundNumber, partition, flatten, negativeMod } = require './common/utils'
config = require('../config').config
pbm = require './ball_model'
plm = require './player_model'
spm = require './shield_powerup_model'
hpm = require './health_powerup_model'
assert = require 'assert'
{ length, scale, invert, normed, normal, sum, diff, cross, makeSegmentBetweenPoints, sect } = require './common/intersect'


PLAYER_IDS = config.player_ids
BALL_SIZE = config.ball_size
ARENA_SIZE = config.arena_size
BALL_LEVELS = config.ball_levels

DIRECTIONS =
  LEFT: 0
  RIGHT: 1



next_ball_id = 0
genBallId = -> next_ball_id++


# Creates an object mapping from player ID to value created by `fn`.
playerIdDict = (fn) ->
  dict ([i, fn(i)] for i in PLAYER_IDS)


# TODO: Pull grid creation out into a set of functions
class @ArenaModel

  constructor: ->
    @game_play = true

    @players = (new plm.PlayerModel(i, config.player_colours[i]) for i in PLAYER_IDS)

    @ball_positions  = @calculateStartPoints(config.dist_between_balls, ARENA_SIZE, BALL_LEVELS)
    @triangles       = @calculateTriangles(BALL_LEVELS)

    @balls = for {x, y} in flatten @ball_positions
      new pbm.BallModel genBallId(), pbm.makePlayerBallType(@nextBallOwner()), x, y

    # Holds all the active balls that players have shot.
    @active_balls = []


  arenaRadius: ->
    Math.max(config.arena_size.x, config.arena_size.y) * 1.42

  # Starting from p, calculates a line to a point that is on a circle with center
  # in (0,0) and radius in (arena.x, arena.y).
  lineToArenaRadius: (p, angle) ->
    target =
      x: p.x + Math.cos(degToRad angle) * @arenaRadius()
      y: p.y + Math.sin(degToRad angle) * @arenaRadius()
    target


  nextBallOwner: () ->
    min = undefined
    for player in @players
      if player.isAlive()
        unless min
          min = player
        else if player.balls_available < min.balls_available
          min = player
    return min


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
    rows = triangleRows(ball_levels)
    half_rows = Math.floor(rows / 2)

    for row in [0...rows]
      cols = trianglesForRow ball_levels, row
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
  rotateTriangles: (arena_size, ball_positions) ->

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
        { x, y } = ball_positions[x][y]
        ball = findBall(x, y)
        # assert(ball, "Error cannot find plasma ball for triangle point")
        if ball?
          if direction == DIRECTIONS.LEFT
            { x: x_new, y: y_new } = triangle[negativeMod(index - 1, triangle_points)]
            { x: x_new, y: y_new } = ball_positions[x_new][y_new]
          else
            { x: x_new, y: y_new } = triangle[negativeMod(index + 1, triangle_points)]
            { x: x_new, y: y_new } = ball_positions[x_new][y_new]
          balls_to_move.push
            ball: ball
            x: x_new
            y: y_new

    # console.log "Balls to move", balls_to_move
    for { ball, x, y } in balls_to_move
      ball.x = x
      ball.y = y

    center_point = { x: arena_size.x/2, y: arena_size.y/2 }
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
      type = pbm.makePlayerBallType(@nextBallOwner())

    @balls.push(new pbm.BallModel(genBallId(), type, x, y))


  setAngle: (player_id, angle) ->
    @players[player_id].turret_angle = angle


  # Tells whether the given ball shadowed by another ball
  shadowed: (player_id, target_ball) ->

    # TODO implement returning the closest one, not the first one we find

    # Position of the ball in the turret
    p = config.player_centers[player_id]

    target_segment = makeSegmentBetweenPoints p, target_ball

    # Ball radius
    BR = config.ball_size / 2

    # Try to find a ball that shadows the target ball
    for b in @balls when b.id != target_ball.id

      # Segment orthogonal to target segment, unit length
      u_n_t = normal(normed target_segment.d)

      # Segment through the ball diameter, orthogonal to target segment
      ball_segment =
        s:
          diff { x: b.x, y: b.y }, (scale u_n_t, BR)
        d:
          scale u_n_t, 2*BR

      # Calculate intersection
      intersection = sect ball_segment, target_segment

      shadow_info =
        ball: b
        target_segment: target_segment
        ball_segment: ball_segment
        intersection: intersection

      if intersection.intersects and intersection.point
        return shadow_info

    return false


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
  # pull_callback : passed (pulled_ball, target_x, target_y), called once
  #                 coords calculated
  #
  pull: (player, x, y, everyone, pull_callback, valid_pull_callback, invalid_pull_callback) ->
    if @game_play
      # Find the balls that were selected by the pull
      r = config.pull_radius
      angle = player.turret_angle

      # Find the balls that were selected by the pull
      [selected, others] = partition @balls, (b, i) ->
        Math.abs(x - b.x) < r and Math.abs(y - b.y) < r

      assert.ok(selected.length in [0,1], "not more than one ball should be selected in a pull")

      if selected.length
        ball = selected[0] #TODO: Hacky, change me

        is_powerup = ball.type.kind == config.ball_kinds.powerup

        shadow_info = @shadowed player.id, ball
        everyone.now.debug_receiveShadow shadow_info

        if s = shadow_info.ball
          log "player #{player} tried to pull ball #{ball.id} at #{[ball.x, ball.y]}
               but it is shadowed by ball #{s.id} at #{[s.x, s.y]}"
          invalid_pull_callback()

        else if is_powerup or ball.type.player_id == player.id
          valid_pull_callback()

          turret_center = config.player_centers[player.id]

          log "player #{player} pulled ball #{ball.id} at", [ball.x, ball.y]

          @balls = others # All other balls stay
          ball.x = turret_center.x
          ball.y = turret_center.y
          pull_callback ball

          unless is_powerup
            player.stored_balls = [ball]
            player.balls_available--

        else
          invalid_pull_callback()


  # TODO update these docs
  # Responsible for handling a player shooting their ball. Calculates ball
  # trajectory and then runs a callback function with target & ball params
  # Does nothing if the player doesn't have any balls
  #
  # player: player to shoot from
  # shot_callback: passed (shot_ball)
  #
  # 1. Identifies a target point ~900px away from the current position
  #    (900 guaruntees it will go off screen).
  # 2. Calculates the target x and y coordinates
  # 3. Deletes the ball from the player's balls
  # 4. Calls the callback function, passing it the ball model and target coords
  shoot: (player, everyone, shot_callback, hit_callback) ->

    if @game_play
      angle = player.turret_angle

      ball = player.stored_balls[0]

      unless ball
        log "player #{player} tries to shoot, but has no ball"
      else
        log "player #{player} shoots ball #{ball.id} of kind #{ball.type.kind} with angle #{angle}"

        # Removes element at index 0
        player.stored_balls.splice(0, 1)
        @active_balls.push ball

        # Calculate which turret was hit, if any

        # Get target segment
        p = config.player_centers[player.id]  # Position of the ball in the turret
        target_point = @lineToArenaRadius p, angle
        target_segment = makeSegmentBetweenPoints p, target_point

        # Get ball segment
        hit_a_player = false
        for target_player in @players when target_player.id != player.id
          do (target_player) ->
            # TODO remove dup

            # Segment orthogonal to target segment, unit length
            u_n_t = normal(normed target_segment.d)

            turret_position = config.player_centers[target_player.id]
            turret_radius = config.shield_radius * player.health

            # Segment through the turret diameter, orthogonal to target segment
            turret_segment =
              s:
                diff turret_position, (scale u_n_t, turret_radius)
              d:
                scale u_n_t, 2*turret_radius

            # Intersect
            intersection = sect turret_segment, target_segment

            will_hit = intersection.intersects and intersection.point

            # Tell other players that ball was shot and if it will hit another player
            shot_callback ball, target_player.id

            if will_hit
              # Hit
              log "will hit: player #{target_player.id}"
              hit_a_player |= true


              # Calculate impact point (where the center of the ball hits the turret radius)
              r = turret_radius
              d = length diff(intersection.point, turret_position)
              m = Math.sqrt(r*r - d*d)
              unit_inverse_target = normed(invert target_segment.d)
              impact = sum intersection.point, scale(unit_inverse_target, m)

              # TODO clean this up, don't hijack intersection
              shadow_info =
                ball: null
                target_segment: target_segment
                ball_segment: turret_segment
                intersection:
                  intersects: true
                  point: impact

              everyone.now.debug_receiveShadow shadow_info

              # Ball arrived at target; do damage
              on_arrive_at_target = =>
                log "ball hit into player #{target_player.id}"

                # Decrease health
                target_player.hit()

                hit_callback target_player

                unless target_player.isAlive()
                  everyone.now.receivePlayerDeath target_player.id
                  @removeAllBallsFromPlayer target_player

              ball.x = impact.x
              ball.y = impact.y
              everyone.now.receiveBallMoved ball, config.shoot_time_ms, ""
              setTimeout on_arrive_at_target, config.shoot_time_ms

            else
              # Not hit
              log "not hit: player #{target_player.id}"

        unless hit_a_player
          ball.x = target_point.x
          ball.y = target_point.y
          everyone.now.receiveBallMoved ball, config.shoot_time_ms, ""


  removeAllBallsFromPlayer: (player) ->
    log "removing all balls of player #{player.id}"
    # TODO implement

    # Populate list of balls to delete
    # bs = (b for b in arena.balls)
    # for b in bs
    #   if b and b.type.player_id == player.id
    #     @balls_to_delete.push b.id


  # Gives a powerup to a player
  #
  # player              : The player who has received the powerup
  # powerup_type        : The type of powerup, types defined in config
  # activateCallback    : Called when the powerup is activated
  # deactivateCallback  : Called when the powerup is deactivated
  setPowerup: (player, powerup_type, activateCallback, deactivateCallback) ->
    log "player #{player.id} has collected a #{powerup_type} powerup"
    player.powerup = switch powerup_type
      when config.powerup_kinds.shield
        new spm.ShieldPowerupModel activateCallback, deactivateCallback
      when config.powerup_kinds.health
        new hpm.HealthPowerupModel player, activateCallback, deactivateCallback

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


  # Sets the game play setting to false so that players can no longer continue playing
  stopGame: ->
    @game_play = false

