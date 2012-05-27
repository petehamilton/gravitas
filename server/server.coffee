http = require "http"
mongodb = require "mongodb"
express = require "express"
nowjs = require "now"

# server = new mongodb.Server "127.0.0.1", 27017, {}

# new mongodb.Db("gravitas", server, {}).open (error, client) ->

  # throw error if error

  # collection = new mongodb.Collection(client, "gravitas_collection")
  # console.log "database connected"

run = ->

  app = express.createServer()
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

  everyone = nowjs.initialize(app, { socketio: {'browser client minification': true} })

  everyone.now.dbGetAll = () ->
    collection.find().toArray (err, results) ->
      console.dir results
      everyone.now.dbReceiveAll results

  fixId = (obj) ->
    obj._id = mongodb.ObjectID obj._id
    obj

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

  setInterval () =>
    fake_pb = {x: Math.random() * 100, y: Math.random() * 100}
    balls = (fake_pb for i in [0..3])
    everyone.now.broadcastPlasmaBalls(fake_pb)
  , 1000

run()
