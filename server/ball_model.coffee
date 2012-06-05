{config} = require './utils'

exports.makePlayerBallType = (player_id) ->
  kind: config.ball_kinds.player
  player_id: player_id


BALL_SIZE = config.ball_size


class @BallModel
  # type examples:
  # - { kind: PLAYER, player_id: 2 }
  # - { kind: POWERUP, effect: SHIELD }
  constructor: (@id, @type, @x, @y) ->
    console.log "Creating Ball #{id} at #{[x, y]}"
