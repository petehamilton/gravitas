class @Turret

  # Positions are clockwise from top left to bottom left
  # 0 => TL, 1 => TR, 2 => BR, 3 => BL
  constructor: (@position) ->
    log "Creating #{@name()}"
    @angle = 45

  name: ->
    "Turret #{@position}"

  # takes a raphael canvas c
  render: (c) ->
    log "Rendering #{@name()}"
    body_center = switch @position
      when 0 then {x: 0, y: 0}
      when 1 then {x: c.width, y: 0}
      when 2 then {x: c.width, y: c.height}
      when 3 then {x: 0, y: c.height}
    log body_center
    
    # simple body (circle!)
    body = c.circle(body_center.x, body_center.y, 80)
            .attr({fill: '#CCCCCC'})

    # turret
    starting_angle = @position * 90 + 45
    turret_width = 100
    turret_height = 15
    turret_center = switch @position
      when 0 then {x: 0, y: -7.5}
      when 1 then {x: c.width, y: -7.5}
      when 2 then {x: c.width, y: c.height - 7.5 }
      when 3 then {x: 0, y: c.height - 7.5}

    turret = c.rect(turret_center.x, turret_center.y, 100, 15)
              .attr({fill: '#FF0000'})
              .attr({"stroke-opacity": 0})
              .transform("r#{starting_angle},#{body_center.x},#{body_center.y}")

    $(document).mousemove (e) =>
      mx = event.pageX
      my = event.pageY

      opp_adj = switch @position
        when 0 then my/mx
        when 1 then (c.width - mx)/my
        when 2 then (c.height - my)/(c.width - mx)
        when 3 then mx/(c.height - my)

      @angle = Math.floor(Math.atan(opp_adj) * (180 / Math.PI)) + @position * 90
      turret.transform("R#{@angle},#{body_center.x},#{body_center.y}")