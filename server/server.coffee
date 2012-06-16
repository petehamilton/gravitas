http = require 'http'
express = require 'express'
nowjs = require 'now'
arena_model = require './arena_model'
pbm = require './ball_model'
spm = require './shield_powerup_model'
db = require './db'
{ log, dir, ServerAnimation, roundNumber } = require './common/utils'
config = require('../config').config


# Server configuration

PORT = 7777
ADDRESS = "0.0.0.0"
MODEL_FPS = config.model_fps
BALLS_ENABLED = config.balls_enabled
ARENA_SIZE = config.arena_size

# Global Variables

arena = new arena_model.ArenaModel()
everyone = null

connected = false

configureNow = (everyone) ->

  nowjs.on 'connect', ->
    console.log "client #{@user.clientId} connected"
    everyone.now.receiveBallsMoved arena.balls
    connected = true


  everyone.now.pingServer = ->
    console.log "pong"


  everyone.now.getUsers = (callback) ->
    db.User.find {}, (err, docs) ->
      callback docs


  everyone.now.authenticate = (user, pw, callback) ->
    db.User.findOne { username: user, password: pw }, (err, u) =>
      if err or not u
        callback { ok: false }
        # Don't disconnect the user (@socket.disconnect())
        # Simply allow them to call authenticate() again.
      else
        log "user #{u.username} authenticated"

        # Connect the nowjs user to the user in our database.
        # This being set marks the user as authenticated.
        # Authorization still needs to be done for every action!
        @user.user_model = u

        callback { ok: true }

  everyone.now.getStats = (user, callback) ->
    db.User.findOne { username: user }, (err, u) ->
      callback
        rating: u.rating
        avatarURL: u.avatarURL
        gamesWon: u.gamesWon
        gamesPlayed: u.gamesPlayed
        timePlayed: u.timePlayed
        achievements: u.achievements
        ratingHistory: u.ratingHistory


  everyone.now.logServer = (msg) ->
    console.log msg


  everyone.now.chat = (msg) ->
    console.log "chat message: #{msg}"
    everyone.now.displayMessage msg


  everyone.now.setAngle = (player_id, angle) ->
    arena.setAngle player_id, angle
    everyone.now.receiveAngle(player_id, angle)

  everyone.now.usePlayerModels = (callback) ->
    callback arena.players


  everyone.now.startGravityGun = (player_id, x, y) ->
    log "Start Gun"
    # TODO remove X, Y only allow pulling balls in line
    player = arena.players[player_id]

    pullCallback = (pulled_ball) =>
      activateCallback = (powerup_type) =>
        everyone.now.receiveActivatePowerup(player_id, powerup_type)

      deactivateCallback = =>
        player.powerup = null
        everyone.now.receiveDeactivatePowerup(player_id)


      everyone.now.receiveBallMoved pulled_ball, config.pull_time_ms
      setTimeout () => # Ball now in turret
        everyone.now.receiveBallInTurret(pulled_ball)
        if pulled_ball.type.kind == config.ball_kinds.powerup
          arena.setPowerup(player, pulled_ball.type.powerup_kind, activateCallback, deactivateCallback)
          everyone.now.receiveMessage player.id, pulled_ball.type.powerup_message

      , config.pull_time_ms

    arena.pull(
      player,
      x,
      y,
      everyone,  # TODO don't do this, use some debug object
      pullCallback,
      => everyone.now.receiveValidPull(player.id),
      => everyone.now.receiveInvalidPull(player.id),
    )


  everyone.now.stopGravityGun = (player_id) ->
    arena.shoot(
      arena.players[player_id]
      everyone
      (shot_ball, hit_player_id) => everyone.now.receiveShot player_id, shot_ball, hit_player_id
      (hit_player) => everyone.now.receiveHealth hit_player.id, hit_player.health
    )


  everyone.now.usePowerup = (player_id) ->
    arena.usePowerup arena.players[player_id]


createApp = ->
  app = express.createServer()
  app.configure -> app.use express.bodyParser()
  app.listen PORT, ADDRESS
  app


# Start the intervals which control ball rotation and the clock
startTimers = ->
  # Ball Triangle Rotations
  @balls_to_delete = []
  ball_rotation = setInterval () =>
    arena.rotateTriangles(ARENA_SIZE, arena.ball_positions)
    if connected
      everyone.now.receiveBallsMoved(arena.balls, config.rotation_time)

      # TODO: Clean me, use .includes? or something
      for b_id in @balls_to_delete
        i = 0
        for b in arena.balls
          if b and b.id == b_id
            everyone.now.receiveRemoveBall(b)
            arena.balls.splice i, 1
          else
            i += 1

      @balls_to_delete = []
  , config.rotation_interval

  # Arena clock time
  seconds = config.game_time
  clock = setInterval () =>
    if connected
      everyone.now.receiveClock --seconds
    if seconds == 0
      clearInterval clock
      clearInterval ball_rotation
  , config.clock_interval


run = ->

  app = createApp()

  db.connect()

  everyone = nowjs.initialize(app, { socketio: {'browser client minification': true} })
  configureNow everyone

  startTimers()

run()
