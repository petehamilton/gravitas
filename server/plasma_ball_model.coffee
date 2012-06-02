config = require('./config').config

exports.makePlayerBallType = (player_id) ->
  kind: config.ball_kinds.player
  player_id: player_id

class @PlasmaBallModel
  # type examples:
  # - { kind: PLAYER, player_id: 2 }
  # - { kind: POWERUP, effect: SHIELD }
  constructor: (@id, @type, @x, @y) ->
    console.log "Creating PlasmaBall"

    @mass = config.ball_mass
    @vortex_mass = config.vortex_mass
    @size = config.ball_size

    @terminal_velocity = config.ball_terminal_velocity

    @vx = @rand(-@terminal_velocity, @terminal_velocity)
    @vy = @rand(-@terminal_velocity, @terminal_velocity)

    # TODO: Remove hard coding
    @ball_boundary = {x: 400 - @size, y: 400 - @size}
    @center = {x: 200, y: 200}


  rand: (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min

  # Used to speed up rendering. Based on half vs full pixel test at:
  # http://www.html5rocks.com/en/tutorials/canvas/performance/#toc-avoid-float
  # Basically, integer coords are easier to render. This is quicker than Math.round
  pixelRound: (val) ->
    rounded = (0.5 + val) | 0;

  # Changes the x and y values based on the respective velocities
  calculateVelocity: (external_masses) ->

    limitVelocity = (velocity) =>
      abs_velocity = Math.abs(velocity)
      sign = (velocity/abs_velocity)
      min = Math.min(abs_velocity, @terminal_velocity)
      return sign * min

    for m in external_masses
      @gravitateTo m

    #TODO: Center hardcoded for now but should be linked to the client side size?
    @vx = limitVelocity @vx
    @vy = limitVelocity @vy

    @x -= @pixelRound(@vx)
    @y -= @pixelRound(@vy)

    # TODO delete ball if it flies out of the arena

  gravitateTo: (other_mass) ->
    dx = @x - other_mass.x
    dy = @y - other_mass.y
    distSq = dx * dx + dy * dy
    dist = Math.sqrt(distSq)

    if dist > 80
      force = @mass * other_mass.mass / distSq
      ax = force * dx / dist
      ay = force * dy / dist

      @vx += ax / @mass
      @vy += ay / @mass

