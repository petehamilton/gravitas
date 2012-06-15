config = require('../config').config
{ ServerAnimation, log } = require './common/utils'

exports.makePlayerBallType = (player) ->
  player.balls_available++
  kind: config.ball_kinds.player
  player_id: player.id

exports.makePowerupBallType = (powerup_kind) ->
  powerup_kinds = config.powerup_kinds
  powerup_messages = config.powerup_messages
  kind: config.ball_kinds.powerup
  powerup_kind: powerup_kind
  powerup_message:
    switch powerup_kind
      when powerup_kinds.shield then powerup_messages.shield
      when powerup_kinds.health then powerup_messages.health


class @BallModel
  # type examples:
  # - { kind: PLAYER, player_id: 2 }
  # - { kind: POWERUP, effect: SHIELD }
  constructor: (@id, @type, @x, @y) ->
    # console.log "Creating Ball #{id} at #{[x, y]}, playerid = #{type.player_id}"
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
