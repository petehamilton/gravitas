class @Game
  constructor: (@arena, @player, @plasmaballs, @server) ->
    # TODO relocate ko
    @lag = ko.observable false
    @player = ko.observable(0).extend { convert: parseInt }
    setupBallMove ()

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

  # zip two arrays together 
  zip = () ->
    lengthArray = (arr.length for arr in arguments)
    length = Math.max(lengthArray...)
    for i in [0...length]
      arr[i] for arr in arguments

  setupBallMove: ->
    now.moveBalls = (coords) ->
      coord_balls = zip (coords, @plasmaballs)
      for (coord, ball) in coord_balls
        ball.attr{x: coord.x, y: coord.y}

