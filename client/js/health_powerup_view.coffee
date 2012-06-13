class @HealthPowerupView
  constructor: (@turret) ->
    log "Creating Health Powerup"


  activate: ->
    log "Playing sound?"
    new Audio("sounds/powerup_health.wav").play()
    @turret.updateHealth config.max_health


  deactivate: ->

