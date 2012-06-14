TURRET_OFFSET = config.turret_offset

class @Turret

  # Positions are clockwise from top left to bottom left
  # 0 => TL, 1 => TR, 2 => BR, 3 => BL
  constructor: (@paper, player_model) ->
    makeTurretOffset = (x, y) =>
      switch @position
        when 0 then { x: @center.x + x, y: @center.y + y }
        when 1 then { x: @center.x - x, y: @center.y + y }
        when 2 then { x: @center.x - x, y: @center.y - y }
        when 3 then { x: @center.x + x, y: @center.y - y }

    animate_pulse = () =>
      @animate_pulse_timer = setTimeout () =>
        @do_pulse()
        animate_pulse() if @alive
      , config.turret_pulse_interval * @pulse_speed

    @position = player_model.id

    log "Creating Turret #{@position}"

    # @image = "../images/double_turret.png"
    @image = "../images/turret2.png"

    @pulse_image = "../images/pulse.png"
    @blast_shield_image = "../images/pulse_shield.png"

    @alive = player_model.alive

    @center = config.player_centers[@position]


    @offset_center = { x: @center.x - TURRET_OFFSET.x, y: @center.y - TURRET_OFFSET.y }

    @angle = @position * 90 + 45

    @pulse_scale = player_model.health
    @shield_radius = config.shield_radius * @pulse_scale

    # Translucent shield background
    @turret_pulse_background = @paper.circle(@center.x, @center.y, @shield_radius)
    @turret_pulse_background.attr
      fill: config.player_colours[@position]
      opacity: 0.2

    # Pulses
    pulse_width = @shield_radius * 2
    pulse_height = @shield_radius * 2
    @pulse_speed = 1
    @pulse_offset_center = { x: @center.x - @shield_radius, y: @center.y - @shield_radius }

    # Static
    @turret_pulse_persist = @paper.image @pulse_image, @pulse_offset_center.x, @pulse_offset_center.y, pulse_width, pulse_height

    # Blast Shield
    @blast_shield = @paper.image @blast_shield_image, @pulse_offset_center.x, @pulse_offset_center.y, pulse_width, pulse_height
    @blast_shield.attr {opacity: 0}

    # Animated Pulse
    @turret_pulse_anim = @paper.image(@pulse_image, @pulse_offset_center.x, @pulse_offset_center.y, @shield_radius*2, @shield_radius*2)
    @turret_pulse_anim.transform("s0").attr {opacity: 1}

    animate_pulse()

    # Turret itself
    width = config.turret_width
    height = config.turret_height
    @turret_sprite = @paper.image(@image, @offset_center.x, @offset_center.y, width, height)
                      .transform("r#{@angle},#{@center.x},#{@center.y}")

  do_pulse: () =>
    @turret_pulse_anim.transform("s0").attr {opacity: 1}
    @turret_pulse_anim.animate({transform:"s#{@pulse_scale}"}, config.turret_pulse_interval*2/3*@pulse_speed, "<>")
    @turret_pulse_anim.animate({opacity: 0}, config.turret_pulse_interval*@pulse_speed, "<>")


  updateHealth: (health) ->
    @pulse_scale = health
    #TODO: Animate this?
    @turret_pulse_anim.animate({transform:"s#{@pulse_scale}"}, config.shield_damage_speed, "<>")
    @turret_pulse_persist.animate({transform:"s#{@pulse_scale}"}, config.shield_damage_speed, "<>")
    @turret_pulse_background.animate({transform:"s#{@pulse_scale}"}, config.shield_damage_speed, "<>")

    if health <= 1 - (config.survivable_hits-1)*0.1 # Warn when one from death
      @pulse_speed = 0.2
      @turret_pulse_background.animate {fill: config.warning_colour}, 500
    else
      @turret_pulse_background.animate {fill: config.player_colours[@position]}, 500


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
    @setRotation angle_degrees if @alive
    angle_degrees


  # sets the turret rotation based on the given angle (in degrees)
  setRotation: (angle) ->
    @angle = angle
    @turret_sprite.transform("R#{@angle},#{@center.x},#{@center.y}")

  generateBlastShield: () ->
    @blast_shield.transform "s#{@pulse_scale}"
    @blast_shield.animate {opacity: 1}, 500, ''


  killBlastShield: () ->
    @blast_shield.animate {opacity: 0}, 500, ''


  # Does a damage animation
  damage: (ball_view, x, y, ballRemoveCallback) ->
    corner_damage = (ball_center, r) ->
      ball_center - r/2 - config.ball_size/2
    corner_ball = (ball_center) ->
      ball_center + config.ball_size/2


    r = 50
    damage_pulse_anim = @paper.image(@pulse_image, corner_damage(x,r), corner_damage(y,r), 2*r, 2*r).transform("s0")
    ballRemoveCallback(corner_ball(@offset_center.x - x), corner_ball(@offset_center.y - y))
    damage_pulse_anim.remove()
    # damage_pulse_anim.animate {transform:"s0.8", opacity: 0.6}, 200, '', () =>
      # damage_pulse_anim.animate {transform:"s1", opacity: 0}, 500, ''
      # ball_view.image.animate {opacity: 0}, 300, ""
      # ball_view.image.animate {transform:"T#{corner_ball(@offset_center.x - x)},#{corner_ball(@offset_center.y - y)}"}, 800, "", () ->
        # damage_pulse_anim.remove()
        # ball_view.image.remove()

  destroy: () ->
    @alive = false
    clearTimeout @animate_pulse_timer
    @pulse_scale = 0.6 # Not full, but bigger than turret
    @do_pulse()

    @turret_sprite.animate({transform: "... r720,#{@center.x},#{@center.y} s0", opacity: 0}, 1000, "")
    @blast_shield.animate({transform: "s0"}, 1000, "")
    @turret_pulse_background.animate({transform: "s0"}, 1000, "")
    @turret_pulse_persist.animate({transform: "s0"}, 1000, "bounce")
