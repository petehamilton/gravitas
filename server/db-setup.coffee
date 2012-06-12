mongoose = require 'mongoose'
db = require './db'
{config, log, dir} = require './utils'


log "Initialising database..."

db.connect()

mongoose.connection.on 'open', ->
  log "Mongoose connected"

  db.setup (err) ->
    if err
      log "Error: ", err

    mongoose.disconnect ->
      log "...done"
      process.exit()
