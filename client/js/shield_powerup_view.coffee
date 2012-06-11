class @ShieldPowerupView
  constructor: (@position, @paper) ->
    log "Creating Shield Powerup #{@position}"


  activate: (turret) ->
    log "ACTIVTE"
    new Audio("sounds/powerup_shield.wav").play()
    turret.pulse_speed = 0.1
    turret.generateBlastShield()


  deactivate: (turret) ->
    new Audio("sounds/powerup_shield.wav").play()
    turret.pulse_speed = 1
    turret.killBlastShield()

