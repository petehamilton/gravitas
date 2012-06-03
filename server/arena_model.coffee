{config} = require './utils'
pbm = require './plasma_ball_model'


PLAYER_IDS = config.player_ids

next_ball_id = 0
genBallId = -> next_ball_id++


class @ArenaModel

  constructor: ->
    starting_coords = ({x: Math.random() * config.arena_size.x, y: Math.random() * config.arena_size.y} for i in PLAYER_IDS)
    @plasma_balls = (new pbm.PlasmaBallModel(genBallId(), pbm.makePlayerBallType(i), starting_coords[i].x, starting_coords[i].y) for i in PLAYER_IDS)

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
      b1_size = b2_size = config.ball_size

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

    vortex_mass =
      mass: config.vortex_mass
      x: config.arena_size.x / 2
      y: config.arena_size.y / 2

    @detectCollisions()

    for ball in @plasma_balls
      ball.calculateVelocity [vortex_mass]

