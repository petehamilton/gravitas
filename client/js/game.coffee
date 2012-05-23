class @Game
  constructor: (@arena, @player, @server) ->

  onOwnAngle: (angle) ->
    @server.setAngle @player, angle

  setAngle: (player, angle) ->
    @arena.setTurretRotation(player, angle)
