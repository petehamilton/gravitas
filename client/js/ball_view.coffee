SPRITE_FOLDER = "../images/balls/"
SIZE = config.ball_size


getSpritePath = (ball_type, config) ->
  filename = switch ball_type.kind
    when config.ball_kinds.player
      assertPlayerId ball_type.player_id

      switch ball_type.player_id
        when 0 then "pb_blue_0.PNG"
        when 1 then "pb_green_0.PNG"
        when 2 then "pb_pink_0.PNG"
        when 3 then "pb_yellow_0.PNG"

    when config.ball_kinds.powerup then "pb_powerup.PNG"

  SPRITE_FOLDER + filename


corner = (ball_center) ->
  ball_center - SIZE / 2

2
class @BallView
  constructor: (@ball_model, @paper) ->
    log "Creating Ball"
    @sprite_path = getSpritePath @ball_model.type, config
    @image = @paper.image(@sprite_path, corner(@ball_model.x), corner(@ball_model.y), SIZE, SIZE).transform "s0"
    @image.animate {transform:"s1"}, 1000, "elastic", () =>
      @update()


  setModel: (@ball_model) ->
    @update()


  update: ->
    # log "Updating Ball", @ball_model
    @image.attr { x: corner(@ball_model.x), y: corner(@ball_model.y) }


  # Removes the ball image
  #
  # callback : Called once image removed
  remove: (callback) ->
    log "remove", @image
    @image.remove()
    callback()


  # Animates the ball image from it's current position to x, y over duration
  #
  # callback : called once animation complete
  moveTo: (x, y, duration, callback) ->
    @image.animate { x: corner(x), y: corner(y) }, duration, 'backOut', callback
