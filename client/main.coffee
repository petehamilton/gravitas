log = (m) ->
  console.log m


class Turret
  constructor: () ->
    log "I am a turret!"


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


$ ->
  host = window.location.hostname
  $.getScript "http://#{host}:7777/nowjs/now.js", ->
    main()

t = new Turret
