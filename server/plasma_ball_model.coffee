class @PlasmaBallModel
  constructor: (@id, @player, @x, @y) ->


    console.log "Creating PlasmaBall"

    @mass = 1
    @vortex_mass = 7000
    @size = 40

    @terminal_velocity = 5
    @vx = @rand(-@terminal_velocity, @terminal_velocity)
    @vy = @rand(-@terminal_velocity, @terminal_velocity)

  rand: (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min

  calculateVelocity: ->
    #TODO: Center hardcoded for now but should be linked to the client side size?
    calculateNewPoint = (center, point) ->
      offset = Math.abs(point - center) - center
      if (offset > center)
        Math.abs(point) - offset
      else
        point

    reverseVelocity = ->
      @vx *= -1
      @vy *= -1

    # TODO: Remove hard coding
    @ball_boundary = {x: 400 - @size, y: 400 - @size}
    center = {x: 200, y: 200}

    @x -= @vx
    @y -= @vy

    adjusted_center = {x: center.x + @rand(-50, 50), y: center.y + @rand(-50, 50)}

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

    @vx = (@vx/@vx) * Math.min(@vx, @terminal_velocity)
    @vy = (@vy/@vy) * Math.min(@vy, @terminal_velocity)

    # TODO why can't I call reverseVelocity() doesnt seem to register
    # changes to vx and vy?!?
    if (@ball_boundary.x < @x or @x < 0) or (@ball_boundary.y  < @y or @y < 0)
      @x = calculateNewPoint(center.x, @x)
      @y = calculateNewPoint(center.y, @y)
      @vx *= -1
      @vy *= -1

