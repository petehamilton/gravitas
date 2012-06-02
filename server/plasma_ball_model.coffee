config = require('./config').config

class @PlasmaBallModel
  constructor: (@id, @player, @x, @y) ->
    console.log "Creating PlasmaBall"

    @mass = config.arena.ball_mass
    @vortex_mass = config.arena.vortex_mass
    @size = config.arena.ball_size

    @terminal_velocity = config.arena.terminal_velocity

    @vx = @rand(-@terminal_velocity, @terminal_velocity)
    @vy = @rand(-@terminal_velocity, @terminal_velocity)

    # TODO: Remove hard coding
    @ball_boundary = {x: 400 - @size, y: 400 - @size}
    @center = {x: 200, y: 200}
    @offset_center = {x: @center.x - @size/2, y: @center.y - @size/2}

  rand: (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min

  # Used to speed up rendering. Based on half vs full pixel test at:
  # http://www.html5rocks.com/en/tutorials/canvas/performance/#toc-avoid-float
  # Basically, integer coords are easier to render. This is quicker than Math.round
  pixelRound: (val) ->
    rounded = (0.5 + val) | 0;

  # Changes the x and y values based on the respective velocities
  calculateVelocity: (external_masses) ->
    calculateNewPoint = (c, point) ->
      offset = Math.abs(point - c) - c
      Math.abs(point) - offset

    reverseVelocity = ->
      @vx *= -1
      @vy *= -1

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


    # TODO why can't I call reverseVelocity() doesnt seem to register
    # changes to vx and vy?!?
    unless ((0 < @x < @ball_boundary.x) and (0 < @y < @ball_boundary.y))
      unless (0 < @x < @ball_boundary.x)
        @x = calculateNewPoint(@offset_center.x, @x)
        @vx *= -1
      unless (0 < @y < @ball_boundary.y)
        @y = calculateNewPoint(@offset_center.y, @y)
        @vy *= -1

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

