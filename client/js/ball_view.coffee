SPRITE_FOLDER = "../images/balls/"


getSpritePath = (ball_type, config) ->
  filename = switch ball_type.kind
    when config.ball_kinds.player
      assertPlayerId ball_type.player_id

      switch ball_type.player_id
        when 0 then "pb_blue_0.png"
        when 1 then "pb_green_0.png"
        when 2 then "pb_pink_0.png"
        when 3 then "pb_yellow_0.png"

    when config.ball_kinds.powerup then "pb_powerup.png"

  SPRITE_FOLDER + filename


class @BallView
  constructor: (@ball_model, @paper) ->
    log "Creating Ball"
    # Set up graphics

    sprite_path = getSpritePath @ball_model.type, config

    size = config.ball_size

    @image = @paper.image(sprite_path, @ball_model.x, @ball_model.y, size, size)

    @update()


  setModel: (@ball_model) ->
    @update()


  update: ->
    # log "Updating Ball"
    # dir @ball_model
    @image.attr { x: @ball_model.x, y: @ball_model.y }
