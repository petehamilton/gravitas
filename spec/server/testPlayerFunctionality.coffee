{PlayerModel} = require '../../server/player_model'
{ShieldPowerupModel} = require '../../server/shield_powerup_model'

config = require('../../config').config

chai = require 'chai'
{ expect } = chai
chai.should()

describe "Player Functionality test", ->
  describe 'Player dies', ->
    it "Hits the player the relevent number of times to kill it and checks its dead", ->
      player = new PlayerModel(0, 0)
      for hit_count in [0..config.survivable_hits]
        player.hit()
      player.isAlive().should.be.false

  describe 'Player is alive on creation', ->
    it "Checks the player is alive once made", ->
      player = new PlayerModel(0,0)
      player.isAlive().should.be.true

  describe 'Player is alive before max hits', ->
    it "Checks the player is alive after every hit until its max hit", ->
      player = new PlayerModel(0, 0)
      for hit_count in [0...config.survivable_hits]
        player.hit()
        player.isAlive().should.be.true

  describe 'Player with shield is not damaged when hit', ->
    it "Checks that the player cannot be hurt if they have a shield and it is activated", ->
      player = new PlayerModel(0, 0)
      shield_powerup = new ShieldPowerupModel

      player.powerup = shield_powerup
      player.powerup.activated = true
      original_health = player.health
      
      player.hit()
      (player.health == original_health).should.be.true
