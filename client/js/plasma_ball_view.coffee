SPRITE_FOLDER = "../images/plasma_balls/"


getSpritePath = (ball_type, config) ->
  filename = switch ball_type.kind
    when config.ball_kinds.player
      assert(ball_type.player_id in config.game.player_ids) # TODO make a shortcut assertion for this

      switch ball_type.player_id
        when 0 then "pb_blue_0.png"
        when 1 then "pb_green_0.png"
        when 2 then "pb_pink_0.png"
        when 3 then "pb_yellow_0.png"

    when config.ball_kinds.powerup then "pb_powerup.png"

  SPRITE_FOLDER + filename


class @PlasmaBallView
  constructor: (@ball_model, @game, @paper) ->
    log "Creating PlasmaBall"

    # Set up graphics

    sprite_path = getSpritePath @ball_model.type, @game.config

    size = @game.config.arena.ball_size

    @image = @paper.image(sprite_path, @ball_model.x, @ball_model.y, size, size)

    # TODO opacity needed?
    # @image.attr({opacity: Math.random()*0.7 + 0.0})

    @update()


  setModel: (@ball_model) ->
    @update()


  update: ->
    # log "Updating Plasma Ball"
    # dir @ball_model
    @image.attr { x: @ball_model.x, y: @ball_model.y }
