class @PlasmaBall
  constructor: () ->
    log "Creating PlasmaBall"
    @time = 0

  render: (canvas) ->
    log "Rendering PlasmaBall"
    @x = canvas.width/2
    @y = canvas.height/2

    @ball = canvas.circle(canvas.width/2, canvas.height/2, 10)
            .attr({fill: '#00ff00', "stroke-opacity": 0})

    setInterval () =>
       @moveIt canvas
    , 100

  rand: (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min

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
