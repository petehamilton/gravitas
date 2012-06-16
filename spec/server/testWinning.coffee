{ ArenaModel } = require '../../server/arena_model'

chai = require 'chai'
{ expect } = chai
chai.should()


describe "Winning Player", ->
  describe "Find Singular Winner", ->
    it "Checks that the winner is the correct player", ->
      arena = new ArenaModel()
      i = 0
      last_player = undefined
      for player in arena.players
        last_player = player
        player.setHealth(i)
        i += 0.1

      arena.getWinners().should.deep.equal [last_player]


  describe "Find Draw", ->
    it "Checks that all players are winners when their health is not changed", ->
      arena = new ArenaModel()
      arena.getWinners().should.deep.equal arena.players
