config = require('../config').config

class @ShieldPowerupModel
  constructor: (@activateCallback, @deactivateCallback) ->
    @duration = 7000
    @activated = false


  # Activate the shield, run the callback which will be a call
  # to everyone.now.xxxxx to trigger client side animations
  activate: () ->
    @activated = true
    @activateCallback(config.powerup_kinds.shield)
    setTimeout () =>
      @deactivate()
    , @duration


  # Deactivate the shield, run the callback which will be a call
  # to everyone.now.xxxxx to trigger client side animations
  deactivate: () ->
    @activated = false
    @deactivateCallback()
