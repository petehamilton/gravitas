# Awesome triangle spinners

makeSpinner = (path) ->
  new Sonic
    width: 18
    height: 18
    stepsPerFrame: 3
    trailLength: 0.7
    pointDistance: 0.02
    fps: 30
    step: "fader"
    setup: -> @_.lineWidth = 3
    path: path


# Creates a double-triangle spinner and returns a span containing it
createSpinners = ->

  spinner1 = makeSpinner [ [ "line", 1, 17, 8, 5 ], [ "line", 8, 5, 16, 17 ], [ "line", 16, 17, 1, 17 ] ]

  spinner2 = makeSpinner [ [ "line", 1, 5, 8, 17 ], [ "line", 8, 17, 16, 5 ], [ "line", 16, 5, 1, 5 ] ]

  spinner1.play()
  spinner2.play()

  return $('<span class="combined-spinner">').append(spinner1.canvas).append(spinner2.canvas)


# Inject spinners on DOM load
$ ->
  $('.spinner').append createSpinners()
