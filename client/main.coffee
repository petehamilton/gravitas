@log = (m) ->
  console.log m

createPaper = (width, height) ->
  paper = Raphael(0, 0, width, height)

  background = paper.rect(0, 0, width, height)
  background.attr({fill: '#000'})

  paper


setupNow = (game) ->

  now.displayMessage = (msg) ->
    log "received message: #{msg}"
    $('#log').append($('<p>').text(msg))

  now.receiveAngle = game.setAngle


setupChat = ->

  $('#chatform').submit ->
    msg = $('#chatinput').val()
    $('#chatinput').val('')
    log msg

    now.chat msg
    false


main = ->

  # create paper
  paper = createPaper 400, 400

  # create game
  @a = arena = new Arena(paper)
  @g = game = new Game(arena, 0, now)
  arena.setGame game

  p = new PlasmaBall()
  p.render(paper)  # TODO remove

  # listen to mouse events
  $(document).mousemove (e) ->
    mx = e.pageX - paper.canvas.offsetLeft
    my = e.pageY - paper.canvas.offsetTop
    arena.mouseMoved(mx, my)

  setupNow game

  now.ready ->
    log "now ready"

    setupChat()


$ ->
  host = window.location.hostname
  $.getScript "http://#{host}:7777/nowjs/now.js", ->
    main()
