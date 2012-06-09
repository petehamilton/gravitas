class @Vortex
  constructor: (@canvas) ->

    sprites = ["cv001.png", "cv002.png", "cv003.png", "cv004.png"]
    sprite_folder = "../images/central_vortex/"

    sprite_paths = ("#{sprite_folder}#{s}" for s in sprites)

    width = 200
    height = 200
    vortex_sprites = (@canvas.image(s, @canvas.width/2 - width/2, @canvas.height/2 - height/2, width, height) for s in sprite_paths)

    @vortices = []
    for v in vortex_sprites
      v.attr({opacity: Math.random() + 0.0})
      @vortices.push
        sprite: v
        direction: 1 - 2 * Math.floor(Math.random() * 2)
        speed: Math.random()

    log "vorticies directions", (v.direction for v in @vortices)

    @setSpeed(5)


  rotateVortices: (v) ->
    for v in @vortices
      v.sprite.transform "... r#{@rotational_speed * v.speed * v.direction},#{@canvas.width/2},#{@canvas.height/2}"


  setSpeed: (speed) ->
    @rotational_speed = speed
