class @PlasmaBallView
  constructor: (model, canvas) ->
    log "Creating PlasmaBall"

    # Construct from model values
    @id = model.id
    @player = model.player

    # Set up graphics
    sprite_folder = "../images/plasma_balls/"
    sprite_prefix = switch @player
      when 0 then "pb_blue_"
      when 1 then "pb_green_"
      when 2 then "pb_pink_"
      when 3 then "pb_yellow_"
    sprite_paths = ("#{sprite_folder}#{sprite_prefix}#{i}.png" for i in [0..2])
    @layers = (canvas.image(s, @x, @y, 40, 40) for s in sprite_paths)
    for b in @layers
      b.attr({opacity: Math.random()*0.7 + 0.0})

    @update(model)

  update: (model) ->
    # log model
    
    # log "Updating Plasma Ball"
    @x = model.x
    @y = model.y

    @render()

  render: ->
    for b in @layers
      b.attr({x: @x, y: @y})
