
SEG_WIDTH = 34
SEG_HEIGHT = 50
class @CountdownTimerView
  constructor: (@paper, @x, @y) ->
    @m_t = 0
    @m_u = 0
    @s_t = 0
    @s_u = 0
    @seconds = 0

    @segments = @paper.set()
    image = "../images/countdownGlowing.png"

    newDigit = (offset) =>
        @paper.image(image, offset, @y, 476, 50).toBack()

    offset = @x
    @m_t_image = newDigit(@x)
    @m_t_image.attr {"clip-rect":"#{offset} #{y} #{SEG_WIDTH} #{SEG_HEIGHT}"}
    
    offset += SEG_WIDTH
    @m_u_image = newDigit(offset)
    @m_u_image.attr {"clip-rect":"#{offset} #{y} #{SEG_WIDTH} #{SEG_HEIGHT}"}

    offset += SEG_WIDTH
    @sep_image = newDigit(offset - 11*SEG_WIDTH)
    @sep_image.attr {"clip-rect":"#{offset} #{y} #{SEG_WIDTH} #{SEG_HEIGHT}"}
    
    offset += SEG_WIDTH
    @s_t_image = newDigit(offset)
    @s_t_image.attr {"clip-rect":"#{offset} #{y} #{SEG_WIDTH} #{SEG_HEIGHT}"}
    
    offset += SEG_WIDTH
    @s_u_image = newDigit(offset)
    @s_u_image.attr {"clip-rect":"#{offset} #{y} #{SEG_WIDTH} #{SEG_HEIGHT}"}

    @render()


  calculate_digits: () ->
    m = Math.floor @seconds / 60
    @m_t = Math.floor m / 10
    @m_u = m % 10

    s = Math.floor @seconds % 60
    @s_t = Math.floor s / 10
    @s_u = s % 10

    console.log this


  render: () ->
    update_image = (img, t, threshold) =>
      if @seconds < threshold
        img.attr {"x":"#{offset - 13*SEG_WIDTH}"}
      else
        img.attr {"x":"#{offset - t*SEG_WIDTH}"}

    offset = @x
    update_image(@m_t_image, @m_t, 600)
    offset += SEG_WIDTH
    update_image(@m_u_image, @m_u, 60)
    offset += 2*SEG_WIDTH
    update_image(@s_t_image, @s_t, 10)
    offset += SEG_WIDTH
    update_image(@s_u_image, @s_u, 1)


  update: (@seconds) ->
    @calculate_digits()
    @render()