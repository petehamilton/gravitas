class @PlasmaBallModel
  constructor: (@id, @player, @x, @y) ->
    console.log "Creating PlasmaBall"

    @mass = 1
    @vortex_mass = 10000
    @size = 40

    @terminal_velocity = 5
    @vx = @rand(-@terminal_velocity, @terminal_velocity)
    @vy = @rand(-@terminal_velocity, @terminal_velocity)

    # TODO: Remove hard coding
    @ball_boundary = {x: 400 - @size, y: 400 - @size}
    @center = {x: 200, y: 200}
    @offset_center = {x: @center.x - @size/2, y: @center.y - @size/2}

  rand: (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min

  calculateVelocity: ->
    #TODO: Center hardcoded for now but should be linked to the client side size?
    calculateNewPoint = (c, point) ->
      offset = Math.abs(point - c) - c
      Math.abs(point) - offset

    reverseVelocity = ->
      @vx *= -1
      @vy *= -1

    limitVelocity = (velocity) ->
      abs_velocity = Math.abs(velocity)
      (velocity/Math.abs velocity) * Math.min(Math.abs velocity, @terminal_velocity)


    @x -= Math.floor(@vx)
    @y -= Math.floor(@vy)

    adjusted_center = {x: @center.x + @rand(-50, 50), y: @center.y + @rand(-50, 50)}

    dx = @x - adjusted_center.x
    dy = @y - adjusted_center.y
    distSq = dx * dx + dy * dy
    dist = Math.sqrt(distSq)

    if dist > 100
      force = @mass * @vortex_mass / distSq
      ax = force * dx / dist
      ay = force * dy / dist

      @vx += ax / @mass
      @vy += ay / @mass

    @vx = limitVelocity @vx
    @vy = limitVelocity @vy

    # TODO why can't I call reverseVelocity() doesnt seem to register
    # changes to vx and vy?!?
    unless ((0 < @x < @ball_boundary.x) and (0 < @y < @ball_boundary.y))
      unless (0 < @x < @ball_boundary.x)
        @x = calculateNewPoint(@offset_center.x, @x)
      unless (0 < @y < @ball_boundary.y)
        @y = calculateNewPoint(@offset_center.y, @y)
      @vx *= -1
      @vy *= -1

