{ config, even, degToRad } = require './utils'
pbm = require './plasma_ball_model'


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


class @ArenaModel

  constructor: ->
    starting_coords = @calculateStartPoints()
    # @plasma_balls = (new pbm.PlasmaBallModel.createFromCenterPoints(genBallId(), pbm.makePlayerBallType(nextPlayerId()), x, y) for {x, y} in starting_coords)
    @plasma_balls = for {x, y} in starting_coords
      new pbm.PlasmaBallModel.createFromCenterPoints genBallId(),
                                                     pbm.makePlayerBallType(nextPlayerId()),
                                                     x,
                                                     y

  # Calculates starting points for all the balls
  calculateStartPoints: ->

    # Calculates the number of balls for a given row
    ballsForRow = (row) ->
      max_index = BALL_LEVELS - 1
      offset = Math.abs (max_index - row)
      max_index - offset + BALL_LEVELS

    dist_between_balls = config.dist_between_balls
    dist_components = {dx: dist_between_balls / 2, dy: Math.sin(degToRad(60)) * dist_between_balls}
    console.log "dx:", dist_components.dx, "dy", dist_components.dy
    center_point = {x: ARENA_SIZE.x/2, y: ARENA_SIZE.y/2}

    start_coords = []
    rows = BALL_LEVELS * 2 - 1

    for row in [0..(rows-1)]
      cols = ballsForRow row
      rows_from_center = Math.abs(BALL_LEVELS - 1 - row)

      for col in [0..cols-1]
        start_coords.push
          x : center_point.x +
              (col - Math.floor(cols / 2)) * dist_between_balls +
              if even cols
                dist_components.dx
              else
                0
          y : center_point.y +
              dist_components.dy * (row - Math.floor(rows / 2))

    return start_coords


  detectCollisions: ->
    # Taken from page 254 of "Actionscript Animation"
    rotate = (x, y, sine, cosine, reverse) =>
      result = {}
      if(reverse)
        result.x = x * cosine + y * sine
        result.y = y * cosine - x * sine
      else
        result.x = x * cosine - y * sine
        result.y = y * cosine + x * sine
      result

    processCollision = (b1, b2) =>
      c1 = b1.getCenter()
      c2 = b2.getCenter()
      dx = c2.x - c1.x
      dy = c2.y - c1.y

      # All our balls have the same mass and size
      b1_mass = b2_mass = config.ball_mass
      b1_size = b2_size = BALL_SIZE

      dist = Math.sqrt(dx*dx + dy*dy)
      if (dist < b1_size/2 + b2_size/2)
        b1.collided = b2.collided = true

        # Calculate angle, sine and cosine
        angle = Math.atan2(dy, dx)
        sine = Math.sin(angle)
        cosine = Math.cos(angle)

        # rotate b1's postion
        pos1 = {x: 0, y: 0}

        # rotate b2's position
        pos2 = rotate(dx, dy, sine, cosine, true)

        # rotate b1's velocity
        vel1 = rotate(b1.vx, b1.vy, sine, cosine, true)

        # rotate b2's velcoity
        vel2 = rotate(b2.vx, b2.vy, sine, cosine, true)

        # collision reaction
        vxTotal = vel1.x - vel2.x
        vel1.x = ((b1_mass - b2_mass) *  vel1.x + 2 * b2_mass * vel2.x)/(b1_mass + b2_mass)
        vel2.x = vxTotal + vel1.x

        # update position
        pos1.x += vel1.x
        pos2.x += vel2.x

        # Rotate positions back
        pos1 = rotate(pos1.x, pos1.y, sine, cosine, false)
        pos2 = rotate(pos2.x, pos2.y, sine, cosine, false)

        # adjust positions
        b2.setFromCenter(b1.x - pos2.x, b1.y - pos2.y)
        b1.setFromCenter(b1.x - pos1.x, b1.y - pos1.y)
        # b2.x = b1.x + pos2.x
        # b2.y = b1.y + pos2.y
        # b1.x += pos1.x
        # b1.y += pos1.y

        # rotate velocities back
        vel1 = rotate(vel1.x, vel1.y, sine, cosine, false)
        vel2 = rotate(vel2.x, vel2.y, sine, cosine, false)
        b1.vx = vel1.x
        b1.vy = vel1.y
        b2.vx = vel2.x
        b2.vy = vel2.y

    # Check collisions O(n^2)
    for b1 in @plasma_balls
      for b2 in @plasma_balls
        if b1.id < b2.id
          processCollision(b1, b2)


  # TODO this is time-independent, balls move faster with higher FPS! Change!
  update: () ->

    # vortex_mass =
    #   mass: config.vortex_mass
    #   x: config.arena_size.x / 2
    #   y: config.arena_size.y / 2

    # @detectCollisions()

    # for ball in @plasma_balls
    #   ball.calculateVelocity [vortex_mass]

