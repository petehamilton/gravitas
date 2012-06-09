
SEG_WIDTH = 34
SEG_HEIGHT = 50
class @CountdownTimerView
  constructor: (@paper, @x, @y) ->
    image = "../images/countdownGlowing.png"
    @seconds = 0
    @digits = ({index: i, val: 13, image: null} for i in [0..4])
    @digits[2].val = 11
    log @digits

    for d in @digits
      offset = @x + d.index * SEG_WIDTH
      d.image = @paper.image(image, offset, @y, 476, 50).toBack()
      d.image.attr {"clip-rect":"#{offset} #{y} #{SEG_WIDTH} #{SEG_HEIGHT}"}

    @render()


  calculate_digits: () ->
    m = Math.floor @seconds / 60
    m_t = Math.floor m / 10
    m_u = m % 10

    s = Math.floor @seconds % 60
    s_t = Math.floor s / 10
    s_u = s % 10

    @digits[0].val = if @seconds < 600 then 13 else m_t
    @digits[1].val = if @seconds < 60 then 13 else m_u
    @digits[3].val = if @seconds < 10 then 13 else s_t
    @digits[4].val = if @seconds < 1 then 13 else s_u


  render: () ->
    for d in @digits
      d.image.attr {"x":"#{(@x + d.index * SEG_WIDTH) - d.val*SEG_WIDTH}"}


  update: (@seconds) ->
    @calculate_digits()
    @render()