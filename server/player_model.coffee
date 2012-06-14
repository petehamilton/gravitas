config = require('../config').config

class @PlayerModel
  constructor: (@id, @colour) ->
    console.log "Creating Player with ID #{@id}"
    @health = 1 # Float from 0..1
    @alive = true
    @powerup = null
    @stored_balls = []
    @turret_angle = 0

    @center = config.player_centers[@id]

    # Number of balls available for player in center
    @balls_available = 0

  isAlive: ->
    @health > config.survivable_hits * config.hit_damage

  setHealth: (@health) ->
    console.log "Setting health to", @health
    unless @isAlive
      @alive = false
