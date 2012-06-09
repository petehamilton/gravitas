class @ShieldPowerupModel
  constructor: (@player, @activateCallback, @deactivateCallback) ->
    @duration = 3000


  # Activate the shield, run the callback which will be a call
  # to everyone.now.xxxxx to trigger client side animations
  activate: () ->
    @activateCallback()
    setTimeout () =>
      @deactivate()
    , @duration


  # Deactivate the shield, run the callback which will be a call
  # to everyone.now.xxxxx to trigger client side animations
  deactivate: () ->
    @deactivateCallback()