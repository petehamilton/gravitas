config = require('../config').config

class @HealthPowerupModel
  constructor: (@player, @activateCallback, @deactivateCallback) ->


  # Activate the health, run the callback which will be a call
  # to everyone.now.xxxxx to trigger client side animations
  activate: ->
    @activated = true
    @player.health = 1
    @activateCallback(config.powerup_kinds.health)


  # Can't deactivate health
  deactivate: ->
    @activated = false
    @deactivateCallback()

  # Returns type
  type: ->
    return config.powerup_kinds.health
