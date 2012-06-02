{config} = require './utils'

exports.makePlayerBallType = (player_id) ->
  kind: config.ball_kinds.player
  player_id: player_id


BALL_MASS = config.ball_mass
TERMINAL_VELOCITY = config.ball_terminal_velocity


class @PlasmaBallModel
  # type examples:
  # - { kind: PLAYER, player_id: 2 }
  # - { kind: POWERUP, effect: SHIELD }
  constructor: (@id, @type, @x, @y) ->
    console.log "Creating PlasmaBall"

    @vx = @rand(-TERMINAL_VELOCITY, TERMINAL_VELOCITY)
    @vy = @rand(-TERMINAL_VELOCITY, TERMINAL_VELOCITY)

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
      min = Math.min(abs_velocity, TERMINAL_VELOCITY)
      return sign * min

    for m in external_masses
      @gravitateTo m

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
      force = BALL_MASS * other_mass.mass / distSq
      ax = force * dx / dist
      ay = force * dy / dist

      @vx += ax / BALL_MASS
      @vy += ay / BALL_MASS

