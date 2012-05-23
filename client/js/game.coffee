class @Game
  constructor: (@arena, @player, @server) ->
    # TODO relocate ko
    @lag = ko.observable false
    @player = ko.observable(0).extend { convert: parseInt }

  # Makes sure the server connection is esablished before executing fn.
  # Otherwise sets the lag indicator.
  withServer: (fn) ->
    timeout = setTimeout (=> @lag on), 250
    @server.ready =>
      clearTimeout timeout
      @lag off
      fn()

  # Sets the turret angle of the current player.
  onOwnAngle: (angle) ->
    @withServer =>
      @server.setAngle @player(), angle

  # Sets the angle of any player turret.
  setAngle: (player, angle) ->
    @arena.setTurretRotation(player, angle)
