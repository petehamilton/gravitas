class @Game
  constructor: (@arena, @player, @server) ->

  onOwnAngle: (angle) ->
    # TODO send the angle to the server
    # @server.setAngle @player, angle

  setAngle: (player, angle) ->
    @arena.setTurretRotation(player, angle)
