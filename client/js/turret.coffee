TURRET_OFFSET = config.turret_offset

class @Turret

  # Positions are clockwise from top left to bottom left
  # 0 => TL, 1 => TR, 2 => BR, 3 => BL
  constructor: (@position, @paper) ->
    log "Creating Turret #{@position}"

    @image = "../images/double_turret.png"
    @pulse_image = "../images/pulse.png"

    @center = config.player_centers[@position]

    makeTurretOffset = (x, y) =>
      switch @position
        when 0 then { x: @center.x + x, y: @center.y + y }
        when 1 then { x: @center.x - x, y: @center.y + y }
        when 2 then { x: @center.x - x, y: @center.y - y }
        when 3 then { x: @center.x + x, y: @center.y - y }

    @offset_center = {x: @center.x - TURRET_OFFSET.x, y: @center.y - TURRET_OFFSET.y}

    @angle = @position * 90 + 45

    # 200x200px pulse image
    pulse_radius = 80

    @body_sprite = @paper.circle(@center.x, @center.y, pulse_radius)
                    .attr({fill: config.player_colours[@position], opacity: 0.2})

    @pulse_offset_center = {x: @center.x - pulse_radius, y: @center.y - pulse_radius}
    @turret_pulse_persist = @paper.image(@pulse_image, @pulse_offset_center.x, @pulse_offset_center.y, pulse_radius*2, pulse_radius*2)
    @turret_pulse_anim = @paper.image(@pulse_image, @pulse_offset_center.x, @pulse_offset_center.y, pulse_radius*2, pulse_radius*2)
    @turret_pulse_anim.transform("s0").attr {opacity: 1}
    pulse_animation = setInterval () =>
        @turret_pulse_anim.transform("s0").attr {opacity: 1}
        @turret_pulse_anim.animate({transform:"s1"}, config.turret_pulse_interval*2/3, "<>")
        @turret_pulse_anim.animate({opacity: 0}, config.turret_pulse_interval, "<>")
    , config.turret_pulse_interval

    width = config.turret_width
    height = config.turret_height

    @turret_sprite = @paper.image(@image, @offset_center.x, @offset_center.y, width, height)
                      .transform("r#{@angle},#{@center.x},#{@center.y}")

    #hp indicator
    @hp_radius = config.hp_radius
    @max_health = config.max_health
    healthdata_display = [9999, 1]

    @getBallStorePos = -> makeTurretOffset 30, 30

    @hp_pos = makeTurretOffset 0, 0

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
    dx = @offset_center.x - mx + TURRET_OFFSET.x
    dy = @offset_center.y - my + TURRET_OFFSET.y

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
