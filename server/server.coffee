http = require 'http'
express = require 'express'
nowjs = require 'now'
arena_model = require './arena_model'
pbm = require './ball_model'
spm = require './shield_powerup_model'
db = require './db'
{log, dir, ServerAnimation} = require './common/utils'
config = require('../config').config


# Server configuration

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
    db.User.findOne { username: user, password: pw }, (err, u) ->
      if err or not u
        callback { ok: false }
      else
        log "user #{u.username} authenticated"
        # TODO send auth token
        callback { ok: true }

  everyone.now.getStats = (user, callback) ->
    db.User.findOne { username: user}, (err, u) ->
      callback
        rating: u.rating
        gamesWon: u.gamesWon
        gamesPlayed: u.gamesPlayed
        timePlayed: u.timePlayed




  # TODO check if we can replace dbInsert and dbUpdate by one dbSave
  everyone.now.dbInsert = (obj) ->
    console.log "inserting", obj
    collection.insert obj, -> everyone.now.dbInsertDone()


  everyone.now.dbUpdate = (obj) ->
    console.log "updating", obj
    fixId obj
    collection.save obj, -> everyone.now.dbUploadDone()


  everyone.now.dbRemove = (obj) ->
    console.log "removing", obj
    fixId obj
    collection.remove { _id: obj._id }, ->
      everyone.now.dbRemoveDone()


  everyone.now.dbDrop = () ->
    console.log "dropping DB"
    collection.remove {}


  everyone.now.fixAllStringIds = () ->
    console.log "fixing all string IDs"
    collection.find().each (err, obj) ->
      # TODO check why obj cursor is null after the last document
      if typeof obj?._id is "string"
        console.log "fixing ", obj
        collection.remove { _id: obj._id }
        collection.save fixId(obj)


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
    # TODO remove X, Y only allow pulling balls in line
    player = arena.players[player_id]

    pullCallback = (pulled_ball, x, y, powerup) =>
      removeBallCallback = =>
        everyone.now.receiveRemoveBall(pulled_ball.x, pulled_ball.y, pulled_ball)

      activateCallback = (powerup_type) =>
        everyone.now.receiveActivatePowerup(player_id, powerup_type)

      deactivateCallback = =>
        player.powerup = null
        everyone.now.receiveDeactivatePowerup(player_id)

      stepCallBack = =>
          everyone.now.receiveBallMoved pulled_ball, 0

      completionCallback = ->
        if powerup
          player = arena.players[player_id]
          removeBallCallback()
          arena.setPowerup(player, pulled_ball.type.powerup_kind, activateCallback, deactivateCallback)
          everyone.now.receiveMessage player.id, pulled_ball.type.powerup_message

      duration = config.pull_time_ms
      pulled_ball.animateTo x, y, duration, stepCallBack, completionCallback


    validPullSoundCallback = =>
      everyone.now.receiveValidPullSound(player.id)

    invalidPullSoundCallback = =>
      everyone.now.receiveInvalidPullSound(player.id)

    arena.pull(player,
               x,
               y,
               pullCallback,
               validPullSoundCallback,
               invalidPullSoundCallback)


  everyone.now.stopGravityGun = (player_id) ->
    shootCallback = (shot_ball, x, y) =>
      everyone.now.receiveShot player_id, shot_ball
      duration = config.shoot_time_ms
      shot_ball.animateTo x, y, duration, () ->
          everyone.now.receiveBallMoved shot_ball, 0
        , () ->
          everyone.now.receiveShotFinished player_id, shot_ball


    arena.shoot arena.players[player_id], shootCallback


  everyone.now.usePowerup = (player_id) ->
    arena.usePowerup arena.players[player_id]


createApp = ->
  app = express.createServer()
  app.configure -> app.use express.bodyParser()
  app.listen 7777, "0.0.0.0"
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
      log "ARENA_BEF: ", (b.id for b in arena.balls)
      log "BALLS_DEL: ", @balls_to_delete
      for b_id in @balls_to_delete
        i = 0
        for b in arena.balls
          if b and b.id == b_id
            everyone.now.receiveRemoveBall(b.x, b.y, b)
            arena.balls.splice i, 1
          else
            i += 1
      log "ARENA_AFT: ", (b.id for b in arena.balls)

      @balls_to_delete = []
  , config.rotation_interval

  # Collision checking
  collisionCheck = setInterval () =>
    arena.processBallPositions (player, ball_model, x, y) ->
      arena.handleCollision player, ball_model, x, y, () =>
        everyone.now.receiveCollisionDamage player.id, ball_model, x, y
        everyone.now.receiveBallMoved ball_model, 0
        if player.health <= config.max_health - config.survivable_hits * config.hit_damage
          everyone.now.receivePlayerDeath player.id

          #TODO:  I think triangles has by this point got a copy
          bs = (b for b in arena.balls)
          for b in bs
            if b and b.type.player_id == player.id
              @balls_to_delete.push b.id
          #TODO: So here, some balls are accidentally re-rendered

        else
          everyone.now.receiveHealthUpdate player.id, player.health
  , config.collision_check_interval

  # Arena clock time
  seconds = config.game_time
  clock = setInterval () =>
    if connected
      everyone.now.receiveClock --seconds
    if seconds == 0
      clearInterval clock
      clearInterval ball_rotation
      clearInterval collisionCheck
  , config.clock_interval


run = ->

  app = createApp()

  db.connect()
  db.configureRoutes app

  everyone = nowjs.initialize(app, { socketio: {'browser client minification': true} })
  configureNow everyone

  startTimers()

run()
