class @ShieldPowerupView
  constructor: (@position, @paper) ->
    log "Creating Shield Powerup #{@position}"

    shield_image = "../images/powerups/powerup_shield.png"

    x = y = 0
    @center = switch @position
        when 0 then { x: x, y: y }
        when 1 then { x: @paper.width - y, y: x }
        when 2 then { x: @paper.width - x, y: @paper.height - y }
        when 3 then { x: y, y: @paper.height - x }

    width = height = 250
    xoffset = width/2
    yoffset = height/2
    @offset_center = switch @position
      when 0 then {x: -xoffset, y: -yoffset}
      when 1 then {x: @paper.width - xoffset, y: -yoffset}
      when 2 then {x: @paper.width - xoffset, y: @paper.height - yoffset }
      when 3 then {x: -xoffset, y: @paper.height - yoffset}

    @number_of_components = 5
    @shield_sprites = for i in [0..@number_of_components-1]
      p = @paper.image(shield_image, @offset_center.x, @offset_center.y, width, height)

      # TODO: For some reason 180 screws up, but either side doesnt. Did a -1 (-5000 marks I know...)
      p.transform("r#{90 * @position - 1},#{@center.x},#{@center.y}")


  activate: () ->
    generateShieldComponent = (i) =>
      setTimeout () =>
        @shield_sprites[i].animate({transform:"r#{90*(@position+1) - 20 * i + 1},#{@center.x},#{@center.y}"}, 1000, '<>')
      , i * 150

    new Audio("sounds/powerup_shield.wav").play()
    for i in [0..@number_of_components-1]
      generateShieldComponent i


  deactivate: () ->
    retractShieldComponent = (i) =>
      setTimeout () =>
        @shield_sprites[i].animate {transform:"r#{90 * @position - 1},#{@center.x},#{@center.y}"}, 1000, () =>
          @shield_sprites[i].remove()
      , i * 150

    new Audio("sounds/powerup_shield.wav").play()
    for i in [0..@number_of_components-1]
      retractShieldComponent i

