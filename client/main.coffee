log (m) ->
  console.log m
  $("#log").append($('<p>').val(m))
  # Output to some other on screen log?

$ ->
  host = window.location.hostname

  $.getScript "http://#{host}:7777/nowjs/now.js", ->

    canvas = $('#main_game_canvas')


    now.displayMessage = (msg) ->
      log "received message: #{msg}"
      $('#log').append ($('<p>').text(msg))



    now.ready ->
      log "now ready"

      $('#chatbutton').click ->
        msg = $('#chatinput').val()
        log msg

        now.chat msg

  t = new Turret

class Turret
  constructor: () ->
    log "I am a turret!"