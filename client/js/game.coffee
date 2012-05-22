class @Game
  constructor: (@canvas, @current_player) ->
    @turrets = (new Turret(p, @canvas) for p in [0..3])

  mouseMoved: (mx, my) ->
    @turrets[@current_player].mouseMoved(mx, my)

  setTurretRotation: (turret, angle) ->
    @turrets[turret].setTurretRotation angle