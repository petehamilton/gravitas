log = (m) ->
  console.log m


class Turret

  # Positions are clockwise from top left to bottom left
  # 0 => TL, 1 => TR, 2 => BR, 3 => BL
  constructor: (@position) ->
    log "Turret Position: #{@position}"

  # takes a raphael canvas c
  render: (c) ->
    log "Rendering"
    
    # simple body (circle!)
    body = c.circle(0, 0, 80)
            .attr({fill: '#CCCCCC'})

    # turret
    turret = c.rect(0, -7.5, 100, 15)
              .attr({fill: '#FF0000'})
              .attr({"stroke-opacity": 0})
              .transform('R45,0,0')

    $(document).mousemove (e) ->
      mx = event.pageX
      my = event.pageY
      angle = Math.floor(Math.atan(my/mx) * (180 / Math.PI))
      log "Angle: #{angle}"
      turret.transform("R#{angle},0,0")



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

  canvas = Raphael(0, 0, canvas_width, canvas_height)
  background = canvas.rect(0, 0, canvas_width, canvas_height)
  background.attr({fill: '#000'})

  # create a new turret
  t = new Turret(0)
  t.render(canvas)


$ ->
  host = window.location.hostname
  $.getScript "http://#{host}:7777/nowjs/now.js", ->
    main()
