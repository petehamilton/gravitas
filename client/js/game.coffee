class @Game
  constructor: (@arena, @player, @server) ->
    @lag = false

  # Controls the lag indicator.
  setLag: (lag) ->
    @lag = lag
    # TODO remove DOM
    if lag
      $('#lag_indicator').addClass 'lag'
    else
      $('#lag_indicator').removeClass 'lag'

  # Makes sure the server connection is esablished before executing fn.
  # Otherwise sets the lag indicator.
  withServer: (fn) ->
    timeout = setTimeout (=> @setLag on), 50
    @server.ready =>
      clearTimeout timeout
      @setLag off
      fn()

  # Sets the turret angle of the current player.
  onOwnAngle: (angle) ->
    @withServer =>
      @server.setAngle @player, angle

  # Sets the angle of any player turret.
  setAngle: (player, angle) ->
    @arena.setTurretRotation(player, angle)
