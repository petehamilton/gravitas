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

calc_vars = {plasma_balls: []}
everyone = null
player_ids = [0..3]

fixId = (obj) ->
  obj._id = mongodb.ObjectID obj._id
  obj

configureNow = (everyone) ->
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

detectCollisions = () ->
  # Taken from page 254 of "Actionscript Animation"
  rotate = (x, y, sine, cosine, reverse) =>
    result = {}
    if(reverse)
      result.x = x * cosine + y * sine
      result.y = y * cosine - x * sine
    else
      result.x = x * cosine - y * sine
      result.y = y * cosine + x * sine
    result

  checkCollision = (b1, b2) =>
    dx = b1.x - b2.x
    dy = b1.y - b2.y
    dist = Math.sqrt(dx*dx + dy*dy)
    if (dist < b1.size/2 + b2.size/2)
      # Calculate angle, sine and cosine
      angle = Math.atan2(dy, dx)
      sine = Math.sin(angle)
      cosine = Math.cos(angle)

      # rotate b1's postion
      pos1 = {x: 0, y: 0}

      # rotate b2's position
      pos2 = rotate(dx, dy, sine, cosine, true)

      # rotate b1's velocity
      vel1 = rotate(b1.vx, b1.vy, sine, cosine, true)

      # rotate b2's velcoity
      vel2 = rotate(b2.vx, b2.vy, sine, cosine, true)

      # collision reaction
      vxTotal = vel1.x + vel2.x
      vel1.x = ((b1.mass - b2.mass) *  vel1.x + 2 * b2.mass * vel2.x)/(b1.mass + b2.mass)
      vel2.x = vxTotal + vel1.x

      # update position
      pos1.x  += vel1.x
      pos2.x += vel2.x

      # Rotate positions back
      pos1 = rotate(pos1.x, pos1.y, sine, cosine, false)
      pos2 = rotate(pos2.x, pos2.y, sine, cosine, false)

      # adjust positions
      b2.x = b1.x + pos2.x
      b2.y = b1.y + pos2.y
      b1.x += pos1.x
      b1.y += pos1.y

      # rotate velocities back
      vel1 = rotate(vel1.x, vel1.y, sine, cosine, false)
      vel2 = rotate(vel2.x, vel2.y, sine, cosine, false)
      b1.vx = vel1.x
      b1.vy = vel1.y
      b2.vx = vel2.x
      b2.vx = vel2.y


  i = 0
  while i < player_ids.length
    j = i + 1
    while j < player_ids.length
      checkCollision(calc_vars.plasma_balls[i], calc_vars.plasma_balls[j])
      j++

    i++


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

  detectCollisions()

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

  app = express.createServer()
  configureApp app

  everyone = nowjs.initialize(app, { socketio: {'browser client minification': true} })
  configureNow everyone
  console.log everyone.now.setAngle

  # performCalculations()
  # sendDataToClient()

  setInterval () =>
    performCalculations()
    sendDataToClient()
  , 30

run()
