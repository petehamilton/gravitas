class @Arena
  constructor: (@paper) ->
    @turrets = (new Turret(p, @paper) for p in [0..3])
    @crosshair = new Crosshair(paper)

    @clock = new CountdownTimer(@paper, 215, 70)


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


  spacebarPressed: () ->
    # Tell the game about the player wanting to use their powerup
    @game.usePowerup()


  setTurretRotation: (turret, angle) ->
    @turrets[turret].setRotation angle


  getBallStorePosition: (player) ->
    @turrets[player].getBallStorePos()
