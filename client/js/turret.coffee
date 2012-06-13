class @Turret

  # Positions are clockwise from top left to bottom left
  # 0 => TL, 1 => TR, 2 => BR, 3 => BL
  constructor: (@position, @paper) ->
    log "Creating Turret #{@position}"

    @image = "../images/double_turret.png"

    makeTurretOffset = (x, y) =>
      switch @position
        when 0 then { x: x, y: y }
        when 1 then { x: @paper.width - y, y: x }
        when 2 then { x: @paper.width - x, y: @paper.height - y }
        when 3 then { x: y, y: @paper.height - x }

    @center = makeTurretOffset 0, 0

    xoffset = 30
    yoffset = 50
    @offset_center = switch @position
      when 0 then {x: -xoffset, y: -yoffset}
      when 1 then {x: @paper.width - xoffset, y: -yoffset}
      when 2 then {x: @paper.width - xoffset, y: @paper.height - yoffset }
      when 3 then {x: -xoffset, y: @paper.height - yoffset}

    @angle = @position * 90 + 45


    # simple body (circle!)
    @body_sprite = @paper.circle(@center.x, @center.y, 80)
                    .attr({fill: '#CCCCCC'})

    width = config.turret_width
    height = config.turret_height

    @turret_sprite = @paper.image(@image, @offset_center.x, @offset_center.y, width, height)
                      .transform("r#{@angle},#{@center.x},#{@center.y}")

    #hp indicator
    @hp_radius = config.hp_radius
    @max_health = config.max_health
    healthdata_display = [9999, 1]

    @getBallStorePos = -> makeTurretOffset 30, 30

    @hp_pos = makeTurretOffset 1.5*@hp_radius, 1.5*@hp_radius

    @updateHpIndicator(66)

    @hp_indicator.each ->
      @sector.scale 0, 0, @cx, @cy
      @sector.animate
        transform: "s1 1 " + @cx + " " + @cy
      , 1000, "bounce"

  # Updates the HP indicator
  updateHpIndicator: (newHealth) ->
    @hp_indicator? @hp_indicator.remove
    if newHealth > @max_health
      @health = @max_health
    else if newHealth < 0
      @health = 0
    else
      @health = newHealth
    healthdata_display = [ @health+1, (100-@health)+1]
    @hp_indicator = @paper.piechart(@hp_pos.x, @hp_pos.y, @hp_radius, healthdata_display,
      {colors:["#57ff53","#ae0800"], smooth: true, stroke: "#57ff53"})

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
