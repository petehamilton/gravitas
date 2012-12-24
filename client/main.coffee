@log = (args...) -> console.log args...
@dir = (obj) -> console.log(JSON.stringify obj)
@assert = (bool, msg) ->
  unless bool
    throw new Error('assertion failed' + if msg? then ' ' + msg else '')

@assertPlayerId = (player_id) ->
  assert(player_id in config.player_ids, "Invalid user id")

@degToRad = (deg) -> (deg * Math.PI) / 180


@zip = () ->
  lengthArray = (arr.length for arr in arguments)
  length = Math.max(lengthArray...)
  for i in [0...length]
    arr[i] for arr in arguments


createPaper = (paperId, width, height, opacity) ->
  paper = Raphael(paperId, width, height)
  background = paper.rect(0, 0, width, height)
  background.attr({fill: '#000', opacity: opacity})
  paper

dlog = (t, o) ->
  $('#dev_log').append($('<p>').text(t + " " + JSON.stringify(o)))
  setTimeout (=> $('#dev_log').empty()), 4000


setupNow = (game) ->

  now.receiveDevLogMessage = (msg) ->
    log "received dev log message: #{msg}"
    $('#dev_log').append($('<p>').text(msg))

  now.receiveAngle = (args...) -> game.setAngle args...
  now.receiveShot = (args...) -> game.shot args...
  now.receiveBallsMoved = (args...) -> game.moveBalls args...
  now.receiveBallMoved = (args...) -> game.moveBall args...
  now.receiveActivatePowerup = (args...) -> game.activatePowerup args...
  now.receiveDeactivatePowerup = (args...) -> game.deactivatePowerup args...
  now.receiveClock = (args...) -> game.clockTick args...
  now.receiveValidPull = (args...) -> game.validPull args...
  now.receiveInvalidPull = (args...) -> game.invalidPull args...
  now.receiveHealth = (args...) -> game.updateHealth args...
  now.receivePlayerDeath = (args...) -> game.killPlayer args...
  now.receiveMessage = (args...) -> game.displayMessage args...  # TODO rename (this is in-battle)
  now.receiveRoomChat = (args...) -> game.roomChat args...
  now.receiveRoomReady = (args...) -> game.roomReady args...
  now.receiveStartGame = (args...) -> game.startGame args...
  now.receivePlayerJoined = (args...) -> game.playerJoined args...
  now.receivePlayerLeft = (args...) -> game.playerLeft args...
  now.receiveBallInTurret = (args...) -> game.ballInTurret args...
  now.receiveRemoveBall = (args...) -> game.removeBall args...
  now.receiveGameOver = (args...) -> game.gameOver args...

  now.debug_receiveShadow = (args...) -> game.debugShadow args...


setupDevLog = ->

  $('#dev_log_chat_form').submit ->
    msg = $('#dev_log_chat_input').val()
    $('#dev_log_chat_input').val('')
    now.devLogChat msg
    false


class FpsThrottler
  constructor: (@fps) ->
    @frameTime = 1000 / @fps
    @lastEventDate = null

  throttle: (fn) ->
    if !@lastEventDate or (new Date() > new Date(@lastEventDate.getTime() + @frameTime))
      @lastEventDate = new Date()
      fn()

main = ->
  # create paper
  paper = createPaper 'paper', config.arena_size.x, config.arena_size.y, 0.3

  # create paper for statistics display
  chartPaper = createPaper 'chartPaper', 430, 120, 0
  piePaper = createPaper 'piePaper', 200, 70, 0


  # create game
  arena = new Arena(paper)

  # create stats page
  statistics = new Statistics(chartPaper,piePaper)

  game = new Game(arena, statistics, 0, now)
  arena.setGame game

  num_colors = 4

  # listen to mouse events
  mouseMoveThrottler = new FpsThrottler config.mouse_move_fps
  $('#paper svg').mousemove (e) ->

    # Fix offsetX/Y for Firefox (where it doesn't exist)
    # if not e.offsetX?
      # ...
      # TODO implement this after finding out why in FF the SVG is not a square despite CSS

    mouseMoveThrottler.throttle ->
      arena.mouseMoved e.offsetX, e.offsetY
      o = {x:e.offsetX, y:e.offsetY}
      $('#dev_log').append($('<p>').text("move " + JSON.stringify(o)))


  # listen to mouse events
  $(paper.canvas).mousedown (e) ->
    arena.mousePressed e.offsetX, e.offsetY
    o = {x:e.offsetX, y:e.offsetY}
    $('#dev_log').append($('<p>').text("down " + JSON.stringify(o)))

  # listen to mouse events
  $(paper.canvas).mouseup (e) ->
    arena.mouseReleased()
    o = {x:e.offsetX, y:e.offsetY}
    $('#dev_log').append($('<p>').text("up " + JSON.stringify(o)))

  # listen to key presses (powerup use)
  $(document).keydown (e) ->
    # log "key pressed", [e.keyCode, e]
    if 48 <= e.keyCode <= 57                 # Keys 1, 2, 3, 4
      game.numberKeyPressed(e.keyCode - 48)
    else switch e.keyCode
      when 13                                # Enter
        game.enterKeyPressed()
      when 32                                # Spacebar
        if game.gameStarted()
          arena.spacebarPressed()
      when 192                               # Ctrl + Backtick
        if e.ctrlKey
          game.debugKeyPressed()


  # Called by inline-js
  # TODO try and put it here. For some reason the events lack fields...
  window.touchstart = (x, y) ->
    arena.mouseMoved x, y
    setTimeout (=> arena.mousePressed x, y), 50

  window.touchend = ->
    arena.mouseReleased()

  window.touchmove = (x, y) ->
    arena.mouseMoved x, y


  # Use game as toplevel knockout ViewModel
  ko.applyBindings game

  setupNow game
  now.ready ->
    log "now ready"

    setupDevLog()

    # Refresh page if server is unreachable for 5 seconds
    popupInterval = null
    popupInterval = setInterval =>
      kill_timeout = setTimeout (=>
        clearInterval popupInterval
        console.error 'you might want to refresh'
      ), 5000
      now.pingServer =>
        clearTimeout kill_timeout
    , 5000

  # Debugging global variables
  @a = arena
  @g = game
  @p = paper


$ ->
  origin = window.location.origin
  $.getScript "#{origin}/nowjs/now.js", ->
    main()

