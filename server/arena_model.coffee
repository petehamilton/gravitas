config = require('./config').config
pbm = require './plasma_ball_model'


PLAYER_IDS = config.game.player_ids

next_ball_id = 0
genBallId = -> next_ball_id++


class @ArenaModel

  constructor: ->
    #TODO: this is a hack, in reality players should ahve multiple plasma balls, change!!!
    starting_coords = ({x: Math.random() * 100, y: Math.random() * 100} for i in PLAYER_IDS)
    @plasma_balls = (new pbm.PlasmaBallModel(genBallId(), pbm.makePlayerBallType(i), starting_coords[i].x, starting_coords[i].y) for i in PLAYER_IDS)
    @turret_masses = [0,0,0,0]

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
      dx = b1.x - b2.x
      dy = b1.y - b2.y
      dist = Math.sqrt(dx*dx + dy*dy)
      if (dist < b1.size/2 + b2.size/2)
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
        vxTotal = vel1.x + vel2.x
        vel1.x = ((b1.mass - b2.mass) *  vel1.x + 2 * b2.mass * vel2.x)/(b1.mass + b2.mass)
        vel2.x = vxTotal + vel1.x

        # update position
        pos1.x += vel1.x
        pos2.x += vel2.x

        # Rotate positions back
        pos1 = rotate(pos1.x, pos1.y, sine, cosine, false)
        pos2 = rotate(pos2.x, pos2.y, sine, cosine, false)

        # adjust positions
        b2.x = b1.x - pos2.x
        b2.y = b1.y - pos2.y
        b1.x -= pos1.x
        b1.y -= pos1.y

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

    # Get the turret masses into a simplified form
    # TODO use map
    turret_masses = []
    for i in PLAYER_IDS
      center = switch i
        when 0 then { x: 0,                   y: 0                   }
        when 1 then { x: config.arena.size.x, y: 0                   }
        when 2 then { x: config.arena.size.x, y: config.arena.size.y }
        when 3 then { x: 0,                   y: config.arena.size.y }

      turret_masses.push
        mass: @turret_masses[i]
        x: center.x
        y: center.y

    # TODO use config / delete these constant things
    vortex = { mass: 10000, x: config.arena.size.x / 2, y: config.arena.size.y / 2 }

    external_masses = turret_masses.concat [vortex]
    # console.log "EXT: ", external_masses

    for ball in @plasma_balls
      ball.calculateVelocity external_masses

    @detectCollisions()

    # Decrease turret pulls
    for i in PLAYER_IDS
      if @turret_masses[i] > 0
        @turret_masses[i] -= 200
        @turret_masses[i] = Math.max(0, @turret_masses[i])

