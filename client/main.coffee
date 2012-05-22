@log = (m) ->
  console.log m
    
main = ->
  canvas = $('#main_game_canvas')

  now.displayMessage = (msg) ->
    log "received message: #{msg}"
    $('#log').append ($('<p>').text(msg))

  now.ready ->
    log "now ready"

    $('#chatform').submit ->
      msg = $('#chatinput').val()
      $('#chatinput').val('')
      log msg

      now.chat msg
      false

  # create canvas
  canvas_width = 400
  canvas_height = 400

  arena = Raphael(100, 100, canvas_width, canvas_height)
  background = arena.rect(0, 0, canvas_width, canvas_height)
  background.attr({fill: '#000'})

  # create a new turret
  @g = new Game(arena, 0)

  p = new PlasmaBall()
  p.render(arena)

  $(document).mousemove (e) =>
    mx = e.pageX - arena.canvas.offsetLeft
    my = e.pageY - arena.canvas.offsetTop
    g.mouseMoved(mx, my)


$ ->
  host = window.location.hostname
  $.getScript "http://#{host}:7777/nowjs/now.js", ->
    main()
