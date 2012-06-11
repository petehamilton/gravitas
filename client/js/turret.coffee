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

    @shield_radius = config.shield_radius

    # Translucent shield background
    @turret_pulse_background = @paper.circle(@center.x, @center.y, @shield_radius)
    @turret_pulse_background.attr
      fill: config.player_colours[@position]
      opacity: 0.2

    # Pulses
    pulse_width = @shield_radius * 2
    pulse_height = @shield_radius * 2
    @pulse_scale = 1
    @pulse_offset_center = {x: @center.x - @shield_radius, y: @center.y - @shield_radius}

    # Static
    @turret_pulse_persist = @paper.image @pulse_image, @pulse_offset_center.x, @pulse_offset_center.y, pulse_width, pulse_height

    # Animated Pulse
    @turret_pulse_anim = @paper.image(@pulse_image, @pulse_offset_center.x, @pulse_offset_center.y, @shield_radius*2, @shield_radius*2)
    @turret_pulse_anim.transform("s0").attr {opacity: 1}

    pulse_animation = setInterval () =>
        @turret_pulse_anim.transform("s0").attr {opacity: 1}
        @turret_pulse_anim.animate({transform:"s#{@pulse_scale}"}, config.turret_pulse_interval*2/3, "<>")
        @turret_pulse_anim.animate({opacity: 0}, config.turret_pulse_interval, "<>")
    , config.turret_pulse_interval

    # Turret itself
    width = config.turret_width
    height = config.turret_height
    @turret_sprite = @paper.image(@image, @offset_center.x, @offset_center.y, width, height)
                      .transform("r#{@angle},#{@center.x},#{@center.y}")
  
  updateHealth: (health) ->
    @pulse_scale = health
    #TODO: Animate this?
    @turret_pulse_anim.animate({transform:"s#{@pulse_scale}"}, config.shield_damage_speed, "<>")
    @turret_pulse_persist.animate({transform:"s#{@pulse_scale}"}, config.shield_damage_speed, "<>")
    @turret_pulse_background.animate({transform:"s#{@pulse_scale}"}, config.shield_damage_speed, "<>")

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
