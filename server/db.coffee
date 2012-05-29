mongodb = require "mongodb"

# server = new mongodb.Server "127.0.0.1", 27017, {}

# new mongodb.Db("gravitas", server, {}).open (error, client) ->

  # throw error if error

  # collection = new mongodb.Collection(client, "gravitas_collection")
  # console.log "database connected"

configureRoutes = (app) ->
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


exports.configureRoutes = configureRoutes
