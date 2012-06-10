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
    sprite_path = getSpritePath @ball_model.type, config
    @image = @paper.image(sprite_path, corner(@ball_model.x), corner(@ball_model.y), SIZE, SIZE).transform "s0"
    @image.animate({transform:"s1"}, 1000, "elastic");
    @update()


  setModel: (@ball_model) ->
    @update()


  update: ->
    # log "Updating Ball", @ball_model
    @image.attr { x: corner(@ball_model.x), y: corner(@ball_model.y) }


  remove: ->
    log "remove", @image
    @image.remove()


  moveTo: (x, y, duration, callback) ->
    @image.animate { x: corner(x), y: corner(y) }, duration, 'backOut', callback


  shoot: (angle, callback) ->
    duration = config.shoot_time_ms
    { x: oldX, y: oldY } = @image.getBBox()

    # Make sure ball flies out of the window
    radius = Math.max(config.arena_size.x, config.arena_size.y) * 1.42

    stretched_target_pos =
      x: oldX + corner(Math.cos(degToRad(angle)) * radius)
      y: oldY + corner(Math.sin(degToRad(angle)) * radius)

    # TODO explosion when turret is hit

    @image.animate stretched_target_pos, duration, '<', =>
      @image.remove()
      callback()
