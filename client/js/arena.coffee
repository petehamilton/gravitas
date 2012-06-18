class @Arena
  constructor: (@paper) ->
    log "Arena created"

  setGame: (@game) ->
    # NOOP

  # Called when a battle start
  start: ->
    assert(@game, "game is not set on Arena.start")

    makeTurrets = (player_models) =>
      log "Creating turrets"
      @turrets = (new Turret(@paper, player) for player in player_models)

    @crosshair = new Crosshair(@paper)
    @clock = new CountdownTimer(@paper, 215, 70)
    @game.usePlayerModels(makeTurrets)

  resetPaper:  ->
    log "Resetting arena paper"
    @paper.clear()

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
    if @turrets[@game.getPlayerId()].alive
      @game.startGravityGun x, y


  mouseReleased: ->
    # Tell the game about the player clicking their mouse
   if @turrets[@game.getPlayerId()].alive
     @game.stopGravityGun()


  spacebarPressed: () ->
    # Tell the game about the player wanting to use their powerup
    if @turrets[@game.getPlayerId()].alive
      @game.usePowerup()


  setTurretRotation: (turret, angle) ->
    @turrets[turret].setRotation angle


  getBallStorePosition: (player) ->
    @turrets[player].getBallStorePos()


  updateHealth: (player_id, health) ->
    log "updateHealth of player #{player_id} to #{health}"
    @turrets[player_id].updateHealth health


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

    { ball_segment, target_segment, intersection } = shadow_info

    shed_arr = hide_arrow ball_segment, 'blue'
    ball_arr = hide_arrow target_segment, 'lightgreen'

    if p = intersection.point
      c = @paper.circle(p.x, p.y, 4).red()
      setTimeout (-> c.remove()), 2000
