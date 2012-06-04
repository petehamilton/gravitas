SPRITE_FOLDER = "../images/balls/"

SIZE = config.ball_size


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


corner = (ball_center) ->
  ball_center - SIZE / 2


class @BallView
  constructor: (@ball_model, @paper) ->
    log "Creating Ball"

    # Set up graphics

    sprite_path = getSpritePath @ball_model.type, config

    @image = @paper.image(sprite_path, corner(@ball_model.x), corner(@ball_model.y), SIZE, SIZE)

    @update()


  setModel: (@ball_model) ->
    @update()


  update: ->
    # log "Updating Ball", @ball_model
    @image.attr { x: corner(@ball_model.x), y: corner(@ball_model.y) }
