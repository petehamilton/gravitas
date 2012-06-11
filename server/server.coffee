http = require 'http'
express = require 'express'
nowjs = require 'now'
arena_model = require './arena_model'
pbm = require './ball_model'
db = require './db'
{config, log, dir} = require './utils'

# Server configuration

MODEL_FPS = config.model_fps
BALLS_ENABLED = config.balls_enabled

# Global Variables

arena = new arena_model.ArenaModel()
everyone = null


configureNow = (everyone) ->

  nowjs.on 'connect', ->
    console.log "client #{@user.clientId} connected"

    # Send initial game parameters
    everyone.now.receiveBalls arena.balls


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

  everyone.now.setAngle = (player, angle) ->
    arena.setAngle player, angle
    everyone.now.receiveAngle(player, angle)

  everyone.now.startGravityGun = (player, x, y) ->
    # TODO remove X, Y only allow pulling balls in line
    arena.pull player, x, y, everyone, (pulled_ball) ->
      everyone.now.receivePull player, pulled_ball

  everyone.now.stopGravityGun = (player) ->
    arena.shoot player, ((shot_ball, angle) ->
          everyone.now.receiveShot player, shot_ball, angle),


createApp = ->
  app = express.createServer()
  app.configure -> app.use express.bodyParser()
  app.listen 7777, "0.0.0.0"
  app


run = ->

  app = createApp()

  db.connect()
  db.configureRoutes app

  everyone = nowjs.initialize(app, { socketio: {'browser client minification': true} })
  configureNow everyone
  console.log everyone.now.setAngle

  setInterval () =>
    log "Rotating"
    arena.rotateTriangles()
    everyone.now.receiveBallMoves(arena.balls)
  , 3000

run()
