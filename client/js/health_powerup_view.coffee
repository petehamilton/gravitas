class @HealthPowerupView
  constructor: (@turret) ->
    log "Creating Health Powerup"


  acquired: ->
    message = @paper.text(config.arena_size.x, config.arena_size.y, "HEALTH POWERUP! \nPress space to activate")

  activate: ->
    log "Playing sound?"
    new Audio("sounds/powerup_health.wav").play()
    @turret.updateHealth config.max_health


  deactivate: ->

