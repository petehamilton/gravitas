class @PlasmaBallModel
  constructor: (@id, @player, @x, @y) ->


    console.log "Creating PlasmaBall"

    @mass = 1
    @vortex_mass = 7000

    @terminal_velocity = 5
    @vx = @rand(-@terminal_velocity, @terminal_velocity)
    @vy = @rand(-@terminal_velocity, @terminal_velocity)

  rand: (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min

  calculateVelocity: ->
    #TODO: Center hardcoded for now but should be linked to the client side size?
    center = {x: 200, y: 200}

    @x -= Math.floor(@vx)
    @y -= Math.floor(@vy)

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

