http = require 'http'
express = require 'express'
nowjs = require 'now'
pbm = require './plasma_ball_model'
db = require './db'

# Server configuration

MODEL_FPS = 60
BALLS_ENABLED = true

# Global Variables

calc_vars = {}
everyone = null
player_ids = [0..3]

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
      performCalculations()
      sendDataToClient()
    , MODEL_FPS
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
    #TODO: This is hardcoded. It should not be.
    turret_mass = 50000

    calc_vars.turret_masses[player] = turret_mass

  everyone.now.stopGravityGun = (player) ->
    calc_vars.turret_masses[player] = 0

  everyone.now.setBallsEnabled = (enabled) ->
    setBallsEnabled enabled
    everyone.now.receiveBallsEnabled enabled


createApp = ->
  app = express.createServer()
  app.configure -> app.use express.bodyParser()
  app.listen 7777, "0.0.0.0"
  app

performCalculations = () ->

  #TODO: Change this to be dynamic as elsewhere
  canvas_size = 400

  # Get the turret masses into a simplified form
  turret_masses = []
  for i in player_ids
    center = switch i
      when 0 then {x: 0, y: 0}
      when 1 then {x: canvas_size, y: 0}
      when 2 then {x: canvas_size, y: canvas_size}
      when 3 then {x: 0, y: canvas_size}

    turret_masses.push {mass: calc_vars.turret_masses[i], x: center.x, y: center.y}

  vortex = {mass: 10000, x: canvas_size/2, y: canvas_size/2}

  external_masses = turret_masses.concat [vortex]
  # console.log "EXT: ", external_masses

  for p in calc_vars.plasma_balls
    p.calculateVelocity(external_masses)

  # Decrease turret pulls
  for i in player_ids
    if calc_vars.turret_masses[i] > 0
      calc_vars.turret_masses[i] -= 200
      calc_vars.turret_masses[i] = Math.max(0, calc_vars.turret_masses[i])


sendDataToClient = () ->
  if everyone.now.receivePlasmaBalls
    everyone.now.receivePlasmaBalls calc_vars.plasma_balls

run = ->
  #TODO: this is a hack, in reality players should ahve multiple plasma balls, change!!!
  starting_coords = ({x: Math.random() * 100, y: Math.random() * 100} for i in player_ids)
  calc_vars.plasma_balls = (new pbm.PlasmaBallModel(i, i, starting_coords[i].x, starting_coords[i].y) for i in player_ids)
  calc_vars.turret_masses = [0,0,0,0]

  app = createApp()
  db.configureRoutes app

  everyone = nowjs.initialize(app, { socketio: {'browser client minification': true} })
  configureNow everyone
  console.log everyone.now.setAngle

  setBallsEnabled on

run()
