class @PlasmaBall
  constructor: (@color) ->
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


    #Graphics
    sprite_folder = "../images/plasma_balls/"
    sprite_prefix = switch @color
      when 0 then "pb_blue_"
      when 1 then "pb_green_"
      when 2 then "pb_pink_"
      when 3 then "pb_yellow_"

    sprite_paths = ("#{sprite_folder}#{sprite_prefix}#{i}.png" for i in [0..2])
    log sprite_paths
    @ball_layers = (canvas.image(s, @x, @y, 40, 40) for s in sprite_paths)
    for b in @ball_layers
      b.attr({opacity: Math.random()*0.7 + 0.0})

    @speeds = [2, -3, -2]
    

    setInterval () =>
       @calculateGravity()
       @move()
    , 50

  rand: (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min

  calculateGravity: ->
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


  move: ->
    for b in @ball_layers
      b.attr({x: @x, y: @y})

    i = 0
    for b in @ball_layers
      b.transform "... r#{@speeds[i]}"
      i += 1

