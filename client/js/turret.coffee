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


  # If the given ball shadowed by another ball, return the shadowing ball closest to the player
  shadowed: (player, ball) ->

    # TODO remove
    makeTurretOffset = (x, y) =>
      switch player
        when 0 then { x: x, y: y }
        when 1 then { x: config.arena_size.x - y, y: x }
        when 2 then { x: config.arena_size.x - x, y: config.arena_size.y - y }
        when 3 then { x: y, y: config.arena_size.y - x }

    # TODO proper player positions
    p = makeTurretOffset 0, 0

    # TODO explain that d is the end
    ball_segment =
      s:
        x: p.x
        y: p.y
      d:
        x: ball.x - p.x
        y: ball.y - p.y


    length = (v) ->
      Math.sqrt(v.x * v.x + v.y * v.y)

    scale = (v, s) ->
      x: v.x * s
      y: v.y * s

    normed = (v) ->
      l = length v
      assert.ok(l > 0, "norm: length > 0")
      scale(v, 1 / l)

    normal = (dv) ->
      # "left-rotated"
      x: -dv.y
      y: dv.x

    diff = (a, b) ->
      x: a.x - b.x
      y: a.y - b.y

    cross = (a, b) ->
      a.x * b.y - a.y * b.y

    # TODO doc
    # see http://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect
    sect = (s1, s2) ->
      # t = (q − p) × s / (r × s)
      [p, q, r, s] = [s1.s, s2.s, s1.d, s1.d]

      if (div = cross r, s) < 0.0001
        null
      else
        t = (cross (diff q, p), s) / div
        # ip = p + t * r
        intersect_point =
          x: p.x + t * r.x
          y: p.y + t * r.y

    # Ball radius
    BR = config.ball_size / 2

    for ob in @balls
      if ob.id != ball.id

        # TODO explain that d is the end
        rot_normed_ball_segment_d = normal(normed ball_segment.d)
        shadow_segment =
          s: diff(ob, (scale rot_normed_ball_segment_d, BR))
            # x: ob.x - rot_normed_ball_segment_d * BR
            # y: ob.y - rot_normed_ball_segment_d * BR
          d: scale(rot_normed_ball_segment_d, 2 * BR)
            # dx: (2 * BR) * rot_normed_ball_segment_d
            # dy: (2 * BR) * rot_normed_ball_segment_d

        log(JSON.stringify { ball: ob, shadow_segment: shadow_segment })

    false

