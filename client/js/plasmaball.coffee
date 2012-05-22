class @PlasmaBall
  render: (c) ->
    log "Rendering PlasmaBall"
    ball = c.circle(c.width/2, c.height/2, 5)
            .attr({fill: '#00ff00', "stroke-opacity": 0})
