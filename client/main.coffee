@log = (args...) ->
  console.log args...

createPaper = (width, height) ->
  paper = Raphael('paper', width, height)  # TODO don't hardcode id here

  background = paper.rect(0, 0, width, height)
  background.attr({fill: '#000'})

  paper


setupNow = (game) ->

  now.displayMessage = (msg) ->
    log "received message: #{msg}"
    $('#log').append($('<p>').text(msg))

  now.receiveAngle = (args...) -> game.setAngle args...


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

  v = new Vortex(paper)
  v.render(paper)
  
  # create game
  @a = arena = new Arena(paper)
  

  @g = game = new Game(arena, 0, now)
  arena.setGame game

  colors = ["#ff0000", "#0000ff", "#00ff00", "#ffff00" ]
  num_balls = 5
  pballs = (new PlasmaBall(colors[i%=num_balls]) for i in [0..num_balls])
  for p in pballs
    p.render(paper)

  # listen to mouse events
  $(document).mousemove (e) ->
    mx = e.pageX - paper.canvas.offsetLeft
    my = e.pageY - paper.canvas.offsetTop
    arena.mouseMoved(mx, my)

  # Use game as toplevel knockout ViewModel
  ko.applyBindings game

  setupNow game

  now.ready ->
    log "now ready"

    setupChat()


$ ->
  host = window.location.hostname
  $.getScript "http://#{host}:7777/nowjs/now.js", ->
    main()
