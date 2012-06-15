mongoose = require 'mongoose'
{log, dir} = require './common/utils'
# TODO put config this into common
config = require('../config').config


MONGO_URL = 'mongodb://localhost/gravitas'


# Models

Achievement_schema = new mongoose.Schema(
  id: Number
  date: String
)

RatingHistory_schema = new mongoose.Schema(
  rating: Number
)


User = mongoose.model 'User', new mongoose.Schema
  id: mongoose.Schema.ObjectId
  username:
    type: String
    index: true
  password: String
  avatarURL: String
  timePlayed: Number
  gamesWon: Number
  gamesPlayed: Number
  rating: Number
  achievements: [ Achievement_schema ]
  ratingHistory: [ RatingHistory_schema ]


connect = ->
  mongoose.connect MONGO_URL


setup = (callback) ->
  User.remove {}, (e) ->
    log "dropped all users"

    for name, pw of config.default_users
      log "inserting userCOFFEE2: #{name}"
      user = new User
        username: name
        password: pw
        avatarURL: "http://i.imgur.com/Ro38G.jpg"
        timePlayed: 39603
        gamesWon: 31
        gamesPlayed: 70
        rating: 1533
        achievements: [
          {id : 0, date : "12.03.2012"}
          {id : 1, date : "14.03.2012"}
          {id : 2, date : ""}
          {id : 3, date : ""}
          {id : 4, date : ""}
        ]
        ratingHistory: [
          {rating : 123}
          {rating : 456}
          {rating : 789}
          {rating : 546}
          {rating : 1123}
          {rating : 1000}
        ]
      user.save callback


exports.MONGO_URL = MONGO_URL
exports.User = User
exports.connect = connect
exports.setup = setup
