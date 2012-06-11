{ config, ServerAnimation, log } = require './utils'

exports.makePlayerBallType = (player_id) ->
  kind: config.ball_kinds.player
  player_id: player_id

exports.makePowerupBallType = (powerup_kind) ->
  kind: config.ball_kinds.powerup
  powerup_kind: powerup_kind


BALL_SIZE = config.ball_size


class @BallModel
  # type examples:
  # - { kind: PLAYER, player_id: 2 }
  # - { kind: POWERUP, effect: SHIELD }
  constructor: (@id, @type, @x, @y) ->
    console.log "Creating Ball #{id} at #{[x, y]}"
    @floating = true

  # Animates a ball model from it's current position to x, y
  # This is done by repeated small step increments
  # 
  # x                   : Target x coord
  # y                   : Target y coord
  # duration            : Duration (ms)
  # stepCallback        : Called every increment of animation
  # completionCallback  : Called once animation is complete
  #                       Not called if animation is overwritten
  animateTo: (x, y, duration, stepCallback, completionCallback) ->
    fps = config.fps
    spf = 1000 / fps
    frames = duration*1.0 / spf

    dx = (x - @x)
    dy = (y - @y)

    i = 0
    original_x = @x
    original_y = @y

    @stopAnimation()
    @animation = setInterval () =>
      if i == frames
        @x = x
        @y = y
        completionCallback() if completionCallback
        @stopAnimation()

      newx = ServerAnimation.easeInOutCubic i, original_x, dx, frames
      newy = ServerAnimation.easeInOutCubic i, original_y, dy, frames
      @x = newx
      @y = newy
      
      stepCallback()
      
      i += 1
    , spf

  stopAnimation: () ->
    clearInterval @animation
