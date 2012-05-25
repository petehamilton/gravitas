class @PlasmaBall
  constructor: (@x, @y) ->
    log "Creating PlasmaBall"
    @time

  render: (canvas) ->
    log "Rendering PlasmaBall"
    ball = canvas.circle(canvas.width/2, canvas.height/2, 10)
            .attr({fill: '#00ff00', "stroke-opacity": 0})
    setInterval((@moveIt canvas), 1)

  rand: (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min

  moveIt: (canvas) ->
    log "Moving PlasmaBall"
    unless @time
      @time = @rand(30, 100)
      deg = @rand(-179, 180)
      vel = @rand(1, 5)
      curve = @rand(0, 1)

    dx = vel * Math.cos (deg * Math.PI/180)
    dy = vel * Math.sin (deg * Math.PI/180)
    
    nowX += dx
    nowY += dy
    
    if nowX < 0
      nowX = canvas.width + nowX
    else
      nowX = nowX % canvas.width

    if nowY < 0
      nowY = canvas.height + nowY
    else
      nowY = nowY % canvas.height

    @x = nowX
    @y = nowY

    if @curve > 0
      deg += 2
    else
      deg -= 2

    @time = @time - 1
    if vel < 1
      @time = 0
    else
      vel = vel - .05

   # setInterval => 
   #    @moveIt (canvas)
   #  , 500

