LAG_LIMIT = 50

class @Game
  constructor: (@arena, @player, @server) ->
    # TODO relocate ko
    @lag = ko.observable false
    @player = ko.observable(0).extend { convert: parseInt }
    @plasma_balls = []

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
    timeout = setTimeout (=> @lag on), LAG_LIMIT
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

  # Sets the (x,y) coords of the plasmaballs
  updatePlasmaBalls: (server_plasma_balls) ->
    server_ids = server_plasma_balls.map (p) -> p.id
    local_ids = @plasma_balls.map (p) -> p.id

    # log @plasma_balls, server_ids, local_ids
    # for p in @plasma_balls
    #   if !(valid_ids.some (id) -> p.id = id)
    #     log "Not There Any More!"
    # @plasma_balls = (p for )

    for p in server_plasma_balls
      if !(local_ids.some (id) -> p.id == id)
        # log "New Plasma Ball!"
        @plasma_balls.push new PlasmaBallView(p, @arena.paper)
      else
        for p2 in @plasma_balls
          if p2.id == p.id
            p2.update(p)
    # @movePlasmaBalls(plasma_balls)
    # @arena.setTurretRotation(player, angle)
