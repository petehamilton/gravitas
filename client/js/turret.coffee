class @Turret

  # Positions are clockwise from top left to bottom left
  # 0 => TL, 1 => TR, 2 => BR, 3 => BL
  constructor: (@position, @paper) ->
    log "Creating Turret #{@position}"

    @image = "../images/double_turret.png"

    @center = switch @position
      when 0 then {x: 0, y: 0}
      when 1 then {x: @paper.width, y: 0}
      when 2 then {x: @paper.width, y: @paper.height}
      when 3 then {x: 0, y: @paper.height}

    xoffset = 30
    yoffset = 50
    @offset_center = switch @position
      when 0 then {x: -xoffset, y: -yoffset}
      when 1 then {x: @paper.width - xoffset, y: -yoffset}
      when 2 then {x: @paper.width - xoffset, y: @paper.height - yoffset }
      when 3 then {x: -xoffset, y: @paper.height - yoffset}

    @angle = @position * 90# + 45

    # simple body (circle!)
    @body_sprite = @paper.circle(@center.x, @center.y, 80)
                    .attr({fill: '#CCCCCC'})

    width = config.turret_width
    height = config.turret_height

    @turret_sprite = @paper.image(@image, @offset_center.x, @offset_center.y, width, height)
                      .transform("r#{@angle},#{@center.x},#{@center.y}")


  # Turns the turret according to the mouse position.
  # Returns the angle in degrees.
  mouseMoved: (mx, my) ->
    dx = @offset_center.x - mx
    dy = @offset_center.y - my

    a = Math.atan(Math.abs(dy/dx))
    if dx > 0 and dy > 0
      angle = Math.PI + a
    else if dx > 0
      angle = Math.PI - a
    else if dy > 0
      angle = 2 * Math.PI - a
    else
      angle = a
    angle_degrees = angle * (180 / Math.PI)
    @setRotation angle_degrees
    angle_degrees

  # sets the turret rotation based on the given angle (in degrees)
  setRotation: (angle) ->
    @angle = angle
    @turret_sprite.transform("R#{@angle},#{@center.x},#{@center.y}")
