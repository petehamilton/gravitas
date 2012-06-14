class @Arena
  constructor: (@paper) ->
    @crosshair = new Crosshair(paper)

    @clock = new CountdownTimer(@paper, 215, 70)

  setGame: (@game) ->
    makeTurrets = (player_models) =>
      @turrets = (new Turret(@paper, player) for player in player_models)

    @game.usePlayerModels(makeTurrets)

  # Gets server side player models
  getPlayerModels: ->
    @game.getPlayerModels()


  mouseMoved: (x, y) ->
    # The turret view calculates the angle and updates itself
    angle = @turrets[@game.getPlayerId()].mouseMoved(x, y)
    @crosshair.mouseMoved(x, y)

    # Tell the game about the changed player angle to send it to the server
    @game.onOwnAngle angle


  mousePressed: (x, y) ->
    # Tell the game about the player clicking their mouse
    @game.startGravityGun x, y


  mouseReleased: (x, y) ->
    # Tell the game about the player clicking their mouse
    @game.stopGravityGun()


  spacebarPressed: () ->
    # Tell the game about the player wanting to use their powerup
    @game.usePowerup()


  setTurretRotation: (turret, angle) ->
    @turrets[turret].setRotation angle


  getBallStorePosition: (player) ->
    @turrets[player].getBallStorePos()


  updateHealth: (player, health) ->
    @turrets[player].updateHealth health

  collisionDamage: (player_id, ball_model, x, y, ballRemoveCallback) ->
    @turrets[player_id].damage(@game.balls[ball_model.id], x, y, ballRemoveCallback)


  killPlayer: (player_id) ->
    turret = @turrets[player_id]
    turret.destroy()


  displayShadow: (shadow_info) ->

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

    { ball_segment, target_segment, intersection_point: p } = shadow_info

    shed_arr = hide_arrow ball_segment, 'blue'
    ball_arr = hide_arrow target_segment, 'lightgreen'

    if p
      c = @paper.circle(p.x, p.y, 4).red()
      setTimeout (-> c.remove()), 2000
