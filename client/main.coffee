log = (m) ->
  console.log m


class Turret
  constructor: () ->
    log "I am a turret!"

  # Positions are clockwise from top left to bottom left
  # 0 => TL, 1 => TR, 2 => BR, 3 => BL
  constructor: (@position) ->
    log "Turret Position: #{@position}"
    this.render()

  render: (canvas) ->
    log "Rendering"
    @

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
  
  t = new Turret(0)


$ ->
  host = window.location.hostname
  $.getScript "http://#{host}:7777/nowjs/now.js", ->
    main()
