mongoose = require 'mongoose'
db = require './db'
{config, log, dir} = require './common/utils'


log "Initialising database..."

db.connect (err) ->
  log "DB connection error: ", err

mongoose.connection.once 'open', ->
  log "Mongoose connected"

  db.setup (err) ->
    if err
      log "Error: ", err

    mongoose.disconnect ->
      log "...done"
      process.exit()
