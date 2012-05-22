class @Turret

  # Positions are clockwise from top left to bottom left
  # 0 => TL, 1 => TR, 2 => BR, 3 => BL
  constructor: (@position) ->
    log "Turret Position: #{@position}"
    @angle = 45

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
      @angle = Math.floor(Math.atan(my/mx) * (180 / Math.PI))
      log "Angle: #{@angle}"
      turret.transform("R#{@angle},0,0")