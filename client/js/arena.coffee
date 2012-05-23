class @Arena
  constructor: (@paper) ->
    @turrets = (new Turret(p, @paper) for p in [0..3])

   setGame: (game) ->
     @game = game

  mouseMoved: (x, y) ->
    # The turret view calculates the angle and updates itself
    angle = @turrets[@game.player].mouseMoved(x, y)

    # Tell the game about the changed player angle to send it to the server
    @game.onOwnAngle angle

  setTurretRotation: (turret, angle) ->
    @turrets[turret].setTurretRotation angle
