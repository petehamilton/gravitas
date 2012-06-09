
SEG_WIDTH = 34
SEG_HEIGHT = 50
class @CountdownTimerView
  constructor: (@paper, @x, @y) ->
    console.log "Countdown Clock Created"
    @m_t = 0
    @m_u = 0
    @s_t = 0
    @s_u = 0

    @segments = @paper.set()
    offset = @x
    @m_t_image = @paper.image("../images/countdownGlowing.gif", offset, @y, 442, 50).toBack()
    @m_t_image.attr {"clip-rect":"#{offset} #{y} #{SEG_WIDTH} #{SEG_HEIGHT}"}
    
    offset += SEG_WIDTH
    @m_u_image = @paper.image("../images/countdownGlowing.gif", offset, @y, 442, 50).toBack()
    @m_u_image.attr {"clip-rect":"#{offset} #{y} #{SEG_WIDTH} #{SEG_HEIGHT}"}

    offset += SEG_WIDTH
    @sep_image = @paper.image("../images/countdownGlowing.gif", offset - 11*SEG_WIDTH, @y, 442, 50).toBack()
    @sep_image.attr {"clip-rect":"#{offset} #{y} #{SEG_WIDTH} #{SEG_HEIGHT}"}
    
    offset += SEG_WIDTH
    @s_t_image = @paper.image("../images/countdownGlowing.gif", offset, @y, 442, 50).toBack()
    @s_t_image.attr {"clip-rect":"#{offset} #{y} #{SEG_WIDTH} #{SEG_HEIGHT}"}
    
    offset += SEG_WIDTH
    @s_u_image = @paper.image("../images/countdownGlowing.gif", offset, @y, 442, 50).toBack()
    @s_u_image.attr {"clip-rect":"#{offset} #{y} #{SEG_WIDTH} #{SEG_HEIGHT}"}

    @render()


  calculate_digits: (seconds) ->
    m = Math.floor seconds / 60
    @m_t = Math.floor m / 10
    @m_u = m % 10

    s = Math.floor seconds % 60
    @s_t = Math.floor s / 10
    @s_u = s % 10

    console.log this


  render: () ->
    offset = @x
    @m_t_image.attr {"x":"#{offset - @m_t*SEG_WIDTH}"}
    offset += SEG_WIDTH
    @m_u_image.attr {"x":"#{offset - @m_u*SEG_WIDTH}"}
    offset += 2*SEG_WIDTH
    @s_t_image.attr {"x":"#{offset - @s_t*SEG_WIDTH}"}
    offset += SEG_WIDTH
    @s_u_image.attr {"x":"#{offset - @s_u*SEG_WIDTH}"}


  update: (s) ->
    console.log "Countdown Timer Updated to #{s}s"
    @calculate_digits s
    @render()