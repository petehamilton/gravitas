plm = require './player_model'
config = require('../config').config

chai = require 'chai'
{ expect } = chai
chai.should()

describe "Player Functionality test", ->
  describe 'Player dies', ->
    it "Hits the player the relevent number of times to kill it and checks its dead", ->
      player = new plm.PlayerModel(0, 0)
      for hit_count in [0..config.survivable_hits]
        player.hit()
      player.isAlive().should.be.false

  describe 'Player is alive on creation', ->
    it "Checks the player is alive once made", ->
      player = new plm.PlayerModel(0,0)
      player.isAlive().should.be.true

  describe 'Player is alive before max hits', ->
    it "Checks the player is alive after every hit until its max hit", ->
      player = new plm.PlayerModel(0, 0)
      for hit_count in [0...config.survivable_hits]
        console.log "Hit count", hit_count
        player.hit()
        player.isAlive().should.be.true
