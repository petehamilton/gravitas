CROSS_SIZE = config.crosshair_size

class @Crosshair
  constructor: (@paper) ->
    log "Creating Crosshair"

    # Set up graphics

    @image = "../images/crosshair/crosshair.png"

    @crosshair_sprite = @paper.image(@image, 0, 0, CROSS_SIZE, CROSS_SIZE)

  mouseMoved: (mx, my) ->
    @crosshair_sprite.attr
      x: mx - (CROSS_SIZE / 2)
      y: my - (CROSS_SIZE / 2)

