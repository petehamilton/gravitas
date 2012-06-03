http = require 'http'
express = require 'express'
nowjs = require 'now'
arena_model = require './arena_model'
pbm = require './plasma_ball_model'
db = require './db'
{config, log, dir} = require './utils'

# Server configuration

MODEL_FPS = config.model_fps
BALLS_ENABLED = config.balls_enabled

# Global Variables

arena = new arena_model.ArenaModel()
everyone = null

ballsEnabled = BALLS_ENABLED
ballsInterval = null

fixId = (obj) ->
  obj._id = mongodb.ObjectID obj._id
  obj


# Turns balls on and off.
setBallsEnabled = (enabled) ->
  ballsEnabled = enabled

  if ballsEnabled
    ballsInterval = setInterval () =>
      # Perform model calculations
      arena.update()
      sendDataToClient()
    , (1000 / MODEL_FPS)
  else
    clearInterval ballsInterval


configureNow = (everyone) ->

  nowjs.on 'connect', ->
    console.log "client #{@user.clientId} connected"

    # Send initial game parameters
    @now.receiveBallsEnabled ballsEnabled

  everyone.now.dbGetAll = () ->
    collection.find().toArray (err, results) ->
      console.dir results
      everyone.now.dbReceiveAll results

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
    everyone.now.receiveAngle(player, angle)

  everyone.now.startGravityGun = (player) ->
    # TODO implement ball pulling
    log "TODO: implement ball pulling"

  everyone.now.stopGravityGun = (player) ->
    # TODO implement ball releasing
    log "TODO: implement ball releasing"

  everyone.now.setBallsEnabled = (enabled) ->
    setBallsEnabled enabled
    everyone.now.receiveBallsEnabled enabled


createApp = ->
  app = express.createServer()
  app.configure -> app.use express.bodyParser()
  app.listen 7777, "0.0.0.0"
  app


sendDataToClient = () ->
  if everyone.now.receivePlasmaBalls
    everyone.now.receivePlasmaBalls arena.balls

run = ->

  app = createApp()
  db.configureRoutes app

  everyone = nowjs.initialize(app, { socketio: {'browser client minification': true} })
  configureNow everyone
  console.log everyone.now.setAngle

  setBallsEnabled on

run()
