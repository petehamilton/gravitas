class @Game
  constructor: (@arena, @player, @server) ->
    # Automatic log-in / start
    @autoLogIn = makeCookieObservable 'autoLogIn'
    @autoStart = makeCookieObservable 'autoStart'

    @autoLogIn.subscribe => @autoStart off if not @autoLogIn()
    @autoStart.subscribe => @autoLogIn on if @autoStart()

    # Log-in / start
    @loggedIn = ko.observable @autoLogIn()
    @gameStarted = ko.observable @autoStart()
    @assembly = ko.observable false


    # Authentication
    @username = ko.observable 'Winston'
    @password = ko.observable ''
    @authFailed = ko.observable false
    @logInButtonText = ko.computed =>
      if @authFailed() then 'Auth failed' else 'Log In'

    @connectedPlayers = ko.observableArray([
      new connectedPlayer("Player A", 321)
      new connectedPlayer("Player XYZ", 456)
    ])

    # Logged in user rating
    @userRating = ko.observable 1554
    @userRatingColor = ko.computed(->
      userRatingRed = ((@userRating()/2200)*255)
      userRatingGreen = (255 - userRatingRed)
      "rgba("+Math.round(userRatingRed)+","+Math.round(userRatingGreen)+",0,0.7)"
    , this )

    # Whether lag is currently happening
    @lag = ko.observable false

    # Current player ID
    @player = ko.observable(0).extend { convert: parseInt }

    # Balls currently in the game. The key is the ball ID.
    @balls = {}

    # Powerups for each player. The key is the player ID
    @powerups = ({i: null} for i in [0..4])

    # Model observable that has a corresponding `.view` observable.
    # Changes to the ".view" are sent to the server using `syncFn`.
    # The `target` observable is to reflect the (shared) actual state,
    # the `.view` one the desired state (e.g. choice of the user).
    withViewObservable = (target, syncFn) =>
      target.view = ko.computed
        read: -> target()
        write: (val) => @withServer -> syncFn val
      target


  resetAuthStatus: =>
    @authFailed false
    true  # continue keypress event


  logIn: =>
    @server.authenticate @username(), @password(), (res) =>
      log res
      if res.ok
        log "login successful"
        @loggedIn true
      else
        log "login failed"
        @authFailed true
        @username ''
        @password ''
    @loggedIn true #TODO: Remove me, I'm for testing only.


  assemblyClick: =>
    @assembly true


  assemblyExitClick: =>
    @assembly false


  # Used to add a new player to the connected players list
  connectNew: =>
    @connectedPlayers.push new connectedPlayer("New", 666)


  startGame: =>
    @gameStarted true


  pingServer: =>
    now.pingServer()


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


  moveBalls: (server_balls) ->
    for ball_model in server_balls
      { x, y } = ball_model
      @moveBall(x, y, 500, ball_model)


  moveBall: (x, y, duration, ball_model) ->
    ball_view = @balls[ball_model.id]
    if ball_view?
      ball_view.moveTo(x, y, duration)
    else
      @balls[ball_model.id] = new BallView(ball_model, @arena.paper)


  pulled: (player, ball_model) ->
    log "player #{player} pulled", ball_model
    {x, y} = @arena.getBallStorePosition player
    duration = config.pull_time_ms
    @moveBall(x, y, duration, ball_model)


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

  # Set the powerup for the current player
  setPowerup: (powerup_type) ->
    @withServer =>
      @server.setPowerup @player(), powerup_type

  # Implement/use the current player's powerup
  usePowerup: () ->
    @withServer =>
      @server.usePowerup @player()

  # Activates the player's current powerup
  activatePowerup: (player, powerup_type) ->
    log "Player #{player} uses their #{powerup_type} powerup"
    p = switch powerup_type
      when "shield" then new ShieldPowerupView(player, @arena.paper)
    @powerups[player] = p
    p.activate()

  # Deactivates the player's current powerup
  deactivatePowerup: (player) ->
    log "Player #{player} loses their powerup"
    p = @powerups[player]
    @powerups[player] = null
    p.deactivate()


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
