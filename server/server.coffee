http = require "http"
mongodb = require "mongodb"
express = require "express"
nowjs = require "now"
pbm = require "./plasma_ball_model"

# server = new mongodb.Server "127.0.0.1", 27017, {}

# new mongodb.Db("gravitas", server, {}).open (error, client) ->

  # throw error if error

  # collection = new mongodb.Collection(client, "gravitas_collection")
  # console.log "database connected"

# Global Variables

calc_vars = {}
everyone = null

fixId = (obj) ->
  obj._id = mongodb.ObjectID obj._id
  obj

setupEveryoneNowFunctions = (everyone) ->
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

  everyone.now.broadcastPlasmaBalls = (plasma_balls) ->
    everyone.now.receivePlasmaBalls plasma_balls

configureApp = (app) -> 
  app.configure ->
    app.use express.bodyParser()

  app.get "/gravitas/all", (req, res, next) ->
    collection.find().toArray (err, results) ->
      console.dir results
      res.send JSON.stringify(results)

  app.get "/gravitas/get/:id?", (req, res, next) ->
    id = req.params.id
    if id
      console.log id
      collection.find({id: id}, {limit: 1}).toArray (err, voc) ->
        console.dir voc[0]
        res.send JSON.stringify(voc[0])
    else
      next()

  app.post "/gravitas/put/", (req, res) ->
    obj = req.body
    collection.update { uid: obj.uid }, obj, { upsert: true }
    res.send req.body

  app.listen 7777, "0.0.0.0"

performCalculations = () ->
  plasma_balls = calc_vars.plasma_balls
  for p in plasma_balls
    p.calculateVelocity()

  # console.log plasma_balls[0] 

sendDataToClient = () ->
  everyone.now.broadcastPlasmaBalls([calc_vars.plasma_balls[0]])

run = ->
  players = [0,1,2,3]

  #TODO: this is a hack, in reality players should ahve multiple plasma balls, change!!!
  starting_coords = ({x: Math.random() * 100, y: Math.random() * 100} for i in [0..3])
  calc_vars.plasma_balls = (new pbm.PlasmaBallModel(i, i, starting_coords[i].x, starting_coords[i].y) for i in [0..3])

  setInterval () =>
    performCalculations()
    sendDataToClient()
  , 30

  app = express.createServer()
  configureApp app

  everyone = nowjs.initialize(app, { socketio: {'browser client minification': true} })
  setupEveryoneNowFunctions everyone

run()
