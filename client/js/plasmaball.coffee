class @PlasmaBall
  constructor: () ->
    log "Creating PlasmaBall"
    @time = 0

    @mass = 1
    @vortex_mass = 7000
    @vx = @rand(-5, 5)
    @vy = @rand(-5, 5)

  render: (canvas) ->
    log "Rendering PlasmaBall"
    @center = {x: canvas.width/2, y: canvas.height/2}
    center_variation = canvas.width/4
    @x = @center.x + @rand(-center_variation, center_variation)
    @y = @center.y + @rand(-center_variation, center_variation)

    @ball = canvas.circle(@x, @y, 10)
            .attr({fill: '#00ff00', "stroke-opacity": 0})

    setInterval () =>
       @moveItGravity()
    , 50

  rand: (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min

  moveItGravity: ->
    @x -= @vx
    @y -= @vy

    adjusted_center = {x: @center.x + @rand(-50, 50), y: @center.y + @rand(-50, 50)}

    dx = @x - adjusted_center.x
    dy = @y - adjusted_center.y
    distSq = dx * dx + dy * dy
    dist = Math.sqrt(distSq)

    if dist > 80
      force = @mass * @vortex_mass / distSq
      ax = force * dx / dist
      ay = force * dy / dist

      @vx += ax / @mass
      @vy += ay / @mass

    @ball.attr({cx: @x, cy: @y})

  moveIt: (canvas) ->
    unless @time
      @time = @rand(30, 100)
      @deg = @rand(-179, 180)
      @vel = @rand(1, 5)
      @curve = @rand(0, 1)

    @x += @vel * Math.cos (@deg * Math.PI/180)
    @y += @vel * Math.sin (@deg * Math.PI/180)
    
    if @x < 0 then @x += canvas.width else @x %= canvas.width

    if @y < 0 then @y += canvas.height else @y %= canvas.height

    if @curve > 0 then @deg += 2 else @deg -= 2

    @ball.attr({cx: @x, cy: @y})
    @time -= 1
