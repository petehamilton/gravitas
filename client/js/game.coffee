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


  # Plays pull sound only if player equals the current player
  pullSound: (player) ->
    if player == @player()
      new Audio("sounds/pull.wav").play()


  # Starts the gravity gun of the current player
  startGravityGun: (x, y) ->
    @withServer =>
      @server.startGravityGun @player(), x, y


  # Stops the turret angle of the current player.
  stopGravityGun: (x, y) ->
    @withServer =>
      @server.stopGravityGun @player()


  # Move the view for the given ball model, takes duration ms
  # For instant movement, pass 0 for duration param
  #
  # ball_model : The ball model for the view we wish to move
  # duration : Animation time
  moveBall: (ball_model, duration) ->
    ball_view = @balls[ball_model.id]
    if ball_view?
      ball_view.moveTo(ball_model.x, ball_model.y, duration)
    else
      @balls[ball_model.id] = new BallView(ball_model, @arena.paper)


  # Move the views for the given ball models, takes duration ms
  # For instant movement, pass 0 for duration param
  #
  # ball_models : The ball models for the views we wish to move
  # duration : Animation time
  moveBalls: (ball_models, duration) ->
    for ball_model in ball_models
      @moveBall(ball_model, duration)


  # A player has shot a ball, play the sound effect and removes the ball from canvas
  #
  # player : the player who shot
  # ball_model : The ball which has been shot
  shot: (player, ball_model) ->
    new Audio("sounds/fire.wav").play()
    log "player #{player} shot", ball_model

  # Player shot done, remove ball from canvas
  #
  # player : the player who shot
  # ball_model : The ball which has been shot
  shotFinished: (player, ball_model) ->
    ball_view = @balls[ball_model.id]
    ball_view.remove =>
      delete @balls[ball_model.id] # TODO check if this allows ball to be GC'd


  # Sets the angle of any player turret.
  setAngle: (player, angle) ->
    if player != @player()
      @arena.setTurretRotation(player, angle)


  # Use the current player's powerup. Sends signal to server
  usePowerup: () ->
    @withServer =>
      @server.usePowerup @player()


  # Activates the player's current powerup
  activatePowerup: (player, powerup_type) ->
    log "Player #{player} uses their #{powerup_type} powerup"
    p = switch powerup_type
      when config.powerup_kinds.shield then new ShieldPowerupView(player, @arena.paper)
    @powerups[player] = p
    p.activate()


  # Deactivates the player's current powerup
  deactivatePowerup: (player) ->
    log "Player #{player} loses their powerup"
    p = @powerups[player]
    @powerups[player] = null
    p.deactivate()

  # Update the arena clock
  clockTick: (seconds) ->
    @arena.clock.update seconds
