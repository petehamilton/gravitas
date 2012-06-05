class @Game
  constructor: (@arena, @player, @server) ->
    # TODO relocate ko
    @loggedIn = ko.observable $.cookie("loggedInCookie")
    @gameStarted = ko.observable $.cookie("gameStartedCookie")

    @username = ko.observable 'Username'
    @password = ko.observable ''

    @logIn = ->
      @loggedIn true

    @connectedPlayers = ko.observableArray([
      new connectedPlayer("Player A", 321)
      new connectedPlayer("Player XYZ", 456)
    ])

    #Used to add a new player to the connected players list
    @connectNew = ->
      @connectedPlayers.push new connectedPlayer("New", 666)

    $("#toggleLogin").attr('checked', @loggedIn());
    $("#toggleGameStarted").attr('checked', @gameStarted());

    $("input#toggleLogin").change ->
      if $(this).is(":checked")
        $.cookie "loggedInCookie", "true"
      else
        $.cookie "loggedInCookie", "true", expires: -1
        $("#toggleGameStarted").attr('checked', false).change();

    $("input#toggleGameStarted").change ->
      if $(this).is(":checked")
        $.cookie "gameStartedCookie", "true"
        $("#toggleLogin").attr('checked', true).change()
      else
        $.cookie "gameStartedCookie", "true", expires: -1

    @startGame = ->
      @gameStarted true


    @pingServer = ->
      now.pingServer()


    ko.bindingHandlers.fadeVisible =
      init: (element, valueAccessor) ->
        value = valueAccessor()
        $(element).toggle ko.utils.unwrapObservable(value)

      update: (element, valueAccessor) ->
        value = valueAccessor()
        (if ko.utils.unwrapObservable(value) then $(element).fadeIn() else $(element).fadeOut())


    @lag = ko.observable false
    @player = ko.observable(0).extend { convert: parseInt }



    # Balls currently in the game. The key is the ball ID.
    @balls = {}

    # Model observable that has a corresponding `.view` observable.
    # Changes to the ".view" are sent to the server using `syncFn`.
    # The `target` observable is to reflect the (shared) actual state,
    # the `.view` one the desired state (e.g. choice of the user).
    withViewObservable = (target, syncFn) =>
      target.view = ko.computed
        read: -> target()
        write: (val) => @withServer -> syncFn val
      target


  #Data structure to hold connected players
  connectedPlayer = (username, rating) ->
    @username = username
    @rating = rating

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
  startGravityGun: (x, y) ->
    new Audio("sounds/pull.wav").play()
    @withServer =>
      @server.startGravityGun @player(), x, y

  # Stops the turret angle of the current player.
  stopGravityGun: (x, y) ->
    @withServer =>
      @server.stopGravityGun @player()

  pulled: (player, ball_model) ->
    log "player #{player} pulled", ball_model
    ball_view = @balls[ball_model.id]
    {x, y} = @arena.getBallStorePosition player
    ball_view.pullTo x, y

  shot: (player, ball_model, angle) ->
    new Audio("sounds/fire.wav").play()
    log "player #{player} shot", ball_model
    ball_view = @balls[ball_model.id]
    ball_view.shoot angle, =>
      # TODO delete ball view / let it fly out/explode
      log "shot done"
      # TODO check if this allow the ball to be GC'd
      delete @balls[ball_model.id]


  # Sets the angle of any player turret.
  setAngle: (player, angle) ->
    if player != @player()
      @arena.setTurretRotation(player, angle)


  updateBalls: (server_balls) ->
    # TODO take care of deleted balls
    for ball_model in server_balls

      ball_view = @balls[ball_model.id]

      if ball_view?
        # Ball already has a view, update model
        ball_view.setModel ball_model
      else
        # Create a new view for this ball. This calls update() for us already.
        @balls[ball_model.id] = new BallView(ball_model, @arena.paper)
