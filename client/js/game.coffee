class @Game
  constructor: (@arena, @player, @server) ->
    # TODO relocate ko
    @lag = ko.observable false
    @player = ko.observable(0).extend { convert: parseInt }

    # Balls currently in the game. The key is the ball ID.
    @plasma_balls = {}

    # Model observable that has a corresponding `.view` observable.
    # Changes to the ".view" are sent to the server using `syncFn`.
    # The `target` observable is to reflect the (shared) actual state,
    # the `.view` one the desired state (e.g. choice of the user).
    withViewObservable = (target, syncFn) =>
      target.view = ko.computed
        read: -> target()
        write: (val) => @withServer -> syncFn val
      target


    @ballsEnabled = withViewObservable (ko.observable false), (val) =>
      @server.setBallsEnabled val


  # Makes sure the server connection is esablished before executing fn.
  # Otherwise sets the lag indicator.
  withServer: (fn) ->
    timeout = setTimeout (=> @lag on), config.lag_limit
    @server.ready =>
      clearTimeout timeout
      @lag off
      fn()

  # Sets the turret angle of the current player.
  onOwnAngle: (angle) ->
    @withServer =>
      @server.setAngle @player(), angle

  # Starts the gravity gun of the current player
  startGravityGun: ->
    new Audio("sounds/pull.wav").play()
    @withServer =>
      @server.startGravityGun @player()

  # Stops the turret angle of the current player.
  stopGravityGun: ->
    @withServer =>
      @server.stopGravityGun @player()

  # Sets the angle of any player turret.
  setAngle: (player, angle) ->
    if player != @player()
      @arena.setTurretRotation(player, angle)

  zip: (args...) ->
    lengthArray = (arr.length for arr in args)
    length = Math.max(lengthArray...)
    for i in [0...length]
      arr[i] for arr in args

  setBallsEnabled: (enabled) ->
    @ballsEnabled enabled

  movePlasmaBalls: (coords) ->
    coord_balls = @zip(coords, @plasma_balls)
    for coord, ball in coord_balls
      ball.attr({x: coord.x, y: coord.y})
    

  updatePlasmaBalls: (server_plasma_balls) ->

    for ball_model in server_plasma_balls

      ball_view = @plasma_balls[ball_model.id]

      if ball_view?
        # Ball already has a view, update model
        ball_view.setModel ball_model
      else
        # Create a new view for this ball. This calls update() for us already.
        @plasma_balls[ball_model.id] = new PlasmaBallView(ball_model, @arena.paper)
