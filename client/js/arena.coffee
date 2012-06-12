class @Arena
  constructor: (@paper) ->
    @turrets = (new Turret(p, @paper) for p in [0..3])
    @crosshair = new Crosshair(paper)


   setGame: (game) ->
     @game = game

  mouseMoved: (x, y) ->
    # The turret view calculates the angle and updates itself
    angle = @turrets[@game.player()].mouseMoved(x, y)
    @crosshair.mouseMoved(x, y)

    # Tell the game about the changed player angle to send it to the server
    @game.onOwnAngle angle

  mousePressed: (x, y) ->
    # Tell the game about the player clicking their mouse
    @game.startGravityGun x, y

  mouseReleased: (x, y) ->
    # Tell the game about the player clicking their mouse
    @game.stopGravityGun()

  setTurretRotation: (turret, angle) ->
    @turrets[turret].setRotation angle

  getBallStorePosition: (player) ->
    @turrets[player].getBallStorePos()

  debugShadowInfo: (si) ->

    Raphael.el.arrow = (color) ->
      @attr
        'stroke': color
        'stroke-width': 3
        'arrow-end': 'classic'

    Raphael.fn.vector = (s, t, color) ->
      @path("M#{s.x} #{s.y}L#{t.x} #{t.y}").arrow(color)

    Raphael.el.red = ->
      @attr
        fill: "#f00"
        stroke: 'none'

    hide_arrow = (segment, color) =>

      { s, d } = segment
      t =
        x: s.x + d.x
        y: s.y + d.y

      arr = @paper.vector(s, t, color)
      setTimeout (-> arr.remove()), 2000

    shed_arr = hide_arrow si.shadow_segment, 'blue'
    ball_arr = hide_arrow si.ball_segment, 'lightgreen'

    p = si.intersection_point

    log "intersection", p
    if p
      c = @paper.circle(p.x, p.y, 4).red()
      setTimeout (-> c.remove()), 2000

