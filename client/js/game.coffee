ARENA_SIZE = config.arena_size

class @Game
  constructor: (@arena, @player, @server) ->
    # Automatic log-in / start
    @autoLogIn = makeCookieObservable 'autoLogIn'
    @autoStart = makeCookieObservable 'autoStart'
    @disableSound = makeCookieObservable 'soundDisabled'


    @autoLogIn.subscribe => @autoStart off unless @autoLogIn()
    @autoStart.subscribe => @autoLogIn on if @autoStart()


    # Log-in / start
    @loggedIn = ko.observable @autoLogIn()
    @gameStarted = ko.observable @autoStart()
    @assembly = ko.observable false

    @assemblyContent = ko.observable 'profile'


    # Authentication
    @username = ko.observable 'lukasz'
    @password = ko.observable 'lukasz'
    @authFailed = ko.observable false
    @logInButtonText = ko.computed =>
      if @authFailed() then 'Auth failed' else 'Log In'

    @connectedPlayers = ko.observableArray([
      new connectedPlayer("Player A", 321)
      new connectedPlayer("Player XYZ", 456)
    ])

    # Logged in user rating
    @gamesWon = ko.observable 0
    @gamesPlayed = ko.observable 0
    @timePlayed =  ko.observable 0
    @timePlayedConverted = ko.computed(=>
      @secToTime(@timePlayed()))
    @userRating = ko.observable 1340
    @userRatingColor = ko.computed(->
      userRatingRed = (((@userRating()-1200)/1000)*255)
      userRatingGreen = (255 - userRatingRed)
      "rgba("+Math.round(userRatingRed)+","+Math.round(userRatingGreen)+",0,0.7)"
    , this )

    # Whether lag is currently happening
    @lag = ko.observable false

    # Current player ID
    # TODO where is the dodgy player reference?
    @player = @getPlayerId = ko.observable(0).extend { convert: parseInt }

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


  assemblyGoTo: (game, event) =>
    @assemblyContent $(event.target).data('menu')




  resetAuthStatus: =>
    @authFailed false
    true  # continue keypress event


  logIn: =>
    @server.authenticate @username(), @password(), (res) =>
      log res
      if res.ok
        log "login successful"
        @getStats()
        @loggedIn true
      else
        log "login failed"
        @authFailed true
        @username ''
        @password ''
   # @loggedIn true #TODO: Remove me, I'm for testing only.

  getStats: =>
    @server.getStats @username(), (res) =>
      @userRating res.rating
      @gamesWon res.gamesWon
      @gamesPlayed res.gamesPlayed
      @timePlayed res.timePlayed



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

  secToTime : (d) ->
    d = Number(d)
    h = Math.floor(d / 3600)
    m = Math.floor(d % 3600 / 60)
    s = Math.floor(d % 3600 % 60)
    (if h > 0 then h + ":" else "") + (if m > 0 then (if h > 0 and m < 10 then "0" else "") + m + ":" else "0:") + (if s < 10 then "0" else "") + s

  # Makes sure the server connection is esablished before executing fn.
  # Otherwise sets the lag indicator.
  withServer: (fn) ->
    timeout = setTimeout (=> @lag on), config.lag_limit
    @server.ready =>
      clearTimeout timeout
      @lag off
      fn()

  # Uses playermodels as the parameter to the callback function
  usePlayerModels: (callback) ->
    @withServer =>
      @server.usePlayerModels callback

  # Sets the turret angle of the current player.
  onOwnAngle: (angle) ->
    @withServer =>
      @server.setAngle @getPlayerId(), angle


  # Plays pull sound only if player equals the current player
  validPullSound: (player) ->
    if player == @getPlayerId() && !@disableSound()
      new Audio("sounds/pull.wav").play()


  # Plays invalid pull sound only if player equals the current player
  invalidPullSound: (player) ->
    if player == @getPlayerId() && !@disableSound()
      new Audio("sounds/funk.wav").play()


  # Starts the gravity gun of the current player
  startGravityGun: (x, y) ->
    @withServer =>
      @server.startGravityGun @getPlayerId(), x, y


  # Stops the turret angle of the current player.
  stopGravityGun: (x, y) ->
    @withServer =>
      @server.stopGravityGun @getPlayerId()


  # Move the view for the given ball model, takes duration ms
  # For instant movement, pass 0 for duration param
  #
  # ball_model : The ball model for the view we wish to move
  # duration : Animation time
  moveBall: (ball_model, duration, callback) ->
    ball_view = @balls[ball_model.id]
    if ball_view?
      ball_view.moveTo(ball_model.x, ball_model.y, duration, callback)
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
    log "player #{player} shot", ball_model
    if !@disableSound()
      log "disableSound:", @disableSound()
      new Audio("sounds/fire.wav").play()


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
    if player != @getPlayerId()
      @arena.setTurretRotation(player, angle)


  # Use the current player's powerup. Sends signal to server
  usePowerup: () ->
    @withServer =>
      @server.usePowerup @getPlayerId()


  # Activates the player's current powerup
  activatePowerup: (player, powerup_type) ->
    log "Player #{player} uses their #{powerup_type} powerup"
    p = switch powerup_type
      when config.powerup_kinds.shield then new ShieldPowerupView(@arena.turrets[player], @arena.paper)
      when config.powerup_kinds.health then new HealthPowerupView(@arena.turrets[player])
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

  # Update the health for the given player
  updateHealth: (player, health) ->
    @arena.updateHealth(player, health)


  removeBall: (x, y, ball_model) ->
    removeBallFromBalls = (ball_id) =>
      assert(delete @balls[ball_id], "Error cannot find ball to remove it client side")

    ball_view = @balls[ball_model.id]
    ball_view.image.animate {opacity: 0}, 300, "", () ->
      ball_view.image.remove()
      removeBallFromBalls(ball_model.id)


  # Deal with a damaging collision
  collisionDamage: (player, ball_model, x, y) ->
    ballRemoveCallback = (x, y) =>
      @removeBall(x, y, ball_model)

    @arena.collisionDamage player, ball_model, x, y, ballRemoveCallback

  killPlayer: (player) ->
    @arena.killPlayer(player)


  # Displays a message, message, temporarily in the centre of the screen for
  # a given player
  displayMessage: (player, message) ->
    if player == @getPlayerId()
      text = @arena.paper.text(ARENA_SIZE.x/2, ARENA_SIZE.y - ARENA_SIZE.y/5, message)
              .attr({"font-size": 20, "fill": "#a2b5c6", 'font-family': "Century Gothic, sans-serif", opacity: 0})
              .transform "s0"
      text.animate {transform: "s1", opacity: 1}, 500, () ->
        setTimeout () =>
          text.animate {opacity: 0}, 1000, () ->
            text.remove()
        , 500


  debugShadow: (shadow_info) ->
    # TODO make a switch to disable this
    log "shadowInfo", shadow_info
    if shadow_info
      @arena.displayShadow shadow_info
