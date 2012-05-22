class @Turret

  # Positions are clockwise from top left to bottom left
  # 0 => TL, 1 => TR, 2 => BR, 3 => BL
  constructor: (@position, @canvas) ->
    log "Creating #{@name()}"

    # body
    @body_center = switch @position
      when 0 then {x: 0, y: 0}
      when 1 then {x: @canvas.width, y: 0}
      when 2 then {x: @canvas.width, y: @canvas.height}
      when 3 then {x: 0, y: @canvas.height}

    # turret
    @angle = @position * 90 + 45
    width = 100
    height = 15
    @center = switch @position
      when 0 then {x: 0, y: -7.5}
      when 1 then {x: @canvas.width, y: -7.5}
      when 2 then {x: @canvas.width, y: @canvas.height - 7.5 }
      when 3 then {x: 0, y: @canvas.height - 7.5}

    @setup()
  name: ->
    "Turret #{@position}"

  # takes a raphael canvas c
  setup: ->
    log "Rendering #{@name()}"
    
    # simple body (circle!)
    @body_sprite = @canvas.circle(@body_center.x, @body_center.y, 80)
                    .attr({fill: '#CCCCCC'})

    @turret_sprite = @canvas.rect(@center.x, @center.y, 100, 15)
              .attr({fill: '#FF0000'})
              .attr({"stroke-opacity": 0})
              .transform("r#{@angle},#{@body_center.x},#{@body_center.y}")

  mouseMoved: (mx, my) ->
    opp_adj = switch @position
      when 0 then my/mx
      when 1 then (c.width - mx)/my
      when 2 then (c.height - my)/(c.width - mx)
      when 3 then mx/(c.height - my)

    angle = Math.floor(Math.atan(opp_adj) * (180 / Math.PI)) + @position * 90
    @setTurretRotation angle

  # sets the turret rotation based on the given angle (in degrees)
  setTurretRotation: (angle) ->
    @angle = angle
    @turret_sprite.transform("R#{@angle},#{@body_center.x},#{@body_center.y}")