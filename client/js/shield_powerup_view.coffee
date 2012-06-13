class @ShieldPowerupView
  constructor: (@turret, @paper) ->
    log "Creating Shield Powerup turret #{@turret}"


  activate: ->
    log "ACTIVTE"
    new Audio("sounds/powerup_shield.wav").play()
    @turret.pulse_speed = 0.1
    @turret.generateBlastShield()


  deactivate: ->
    new Audio("sounds/powerup_shield.wav").play()
    @turret.pulse_speed = 1
    @turret.killBlastShield()

