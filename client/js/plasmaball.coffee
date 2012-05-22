class @PlasmaBall
  render: (c) ->
    log "Rendering PlasmaBall"

    ball = c.circle(c.width, c.height, 5)
            .attr({fill: '#00ff00'})