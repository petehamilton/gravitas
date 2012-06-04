@log = (args...) -> console.log args...
@dir = (obj) -> console.log(JSON.stringify obj)
@assert = (bool, msg) ->
  if not bool
    throw new Error('assertion failed' + if msg? then ' ' + msg else '')

@assertPlayerId = (player_id) ->
  assert(player_id in config.player_ids, "Invalid user id")


@zip = () ->
  lengthArray = (arr.length for arr in arguments)
  length = Math.max(lengthArray...)
  for i in [0...length]
    arr[i] for arr in arguments


createPaper = (paperId, width, height) ->
  paper = Raphael(paperId, width, height)

  background = paper.rect(0, 0, width, height)
  background.attr({fill: '#000'})

  paper


setupNow = (game) ->

  now.displayMessage = (msg) ->
    log "received message: #{msg}"
    $('#log').append($('<p>').text(msg))

  now.receiveAngle = (args...) -> game.setAngle args...
  now.receiveBalls = (args...) -> game.updateBalls args...

setupChat = ->

  $('#chatform').submit ->
    msg = $('#chatinput').val()
    $('#chatinput').val('')
    log "chat message:", msg

    now.chat msg
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
  paper = createPaper 'paper', config.arena_size.x, config.arena_size.y

  vortex = new Vortex(paper)


  # create game
  arena = new Arena(paper)

  game = new Game(arena, 0, now)
  arena.setGame game

  num_colors = 4

  # listen to mouse events
  mouseMoveThrottler = new FpsThrottler config.fps
  $('#paper').mousemove (e) ->
    mouseMoveThrottler.throttle ->
      arena.mouseMoved(e.offsetX, e.offsetY)


  # listen to mouse events
  $(paper.canvas).mousedown (e) ->
    arena.mousePressed()

  # listen to mouse events
  $(paper.canvas).mouseup (e) ->
    arena.mouseReleased()

  # Use game as toplevel knockout ViewModel
  ko.applyBindings game

  setupNow game

  now.ready ->
    log "now ready"

    setupChat()

  # Debugging global variables
  @a = arena
  @g = game
  @p = paper


$ ->
  host = window.location.hostname
  $.getScript "http://#{host}:7777/nowjs/now.js", ->
    main()

