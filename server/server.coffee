http = require 'http'
express = require 'express'
nowjs = require 'now'
_ = require './lib/underscore'
arena_model = require './arena_model'
pbm = require './ball_model'
spm = require './shield_powerup_model'
db = require './db'
{ log, dir, ServerAnimation, roundNumber } = require './common/utils'
config = require('../config').config


# Server configuration

PORT = 7777
ADDRESS = "0.0.0.0"
MODEL_FPS = config.model_fps
BALLS_ENABLED = config.balls_enabled
ARENA_SIZE = config.arena_size

# Global Variables

arena = new arena_model.ArenaModel()
everyone = null

connected = false


# Available game rooms. Key: room ID
rooms = {}
next_room_id = 0


class Room
  constructor: ->
    # Stores nowjs clients (the User class, not the User#user namespace)
    # We call them "client" througout this class to avoid confusion with User.user and our DB User
    @clients = [ null, null, null, null ]
    @num_clients = 0

  getClients: ->
    _.filter @clients, (c) -> c != null

  addClient: (client) ->
    # TODO highlevel this with underscore
    for c, i in @clients when c == null
      @clients[i] = client
      @num_clients++
      return
    throw new Error('room is full!')

  removeClient: (client) ->
    for c, i in @clients when c == client
      @clients[i] = null
      @num_clients--
      return
    throw new Error("room doesn't contain clientId #{clientId}!")

  full: ->
    @num_clients == @clients.length


# Creates a new room, adds it to the available rooms and returns the room ID
allocateNewRoom = ->
  id = next_room_id++
  rooms[id] = new Room()
  id


# TODO allocate room based on player skills
getSuitableRoom = ->
  for id, r of rooms
    if not r.full()
      return id
  null


configureNow = (everyone) ->

  nowjs.on 'connect', ->
    console.log "client #{@user.clientId} connected"
    everyone.now.receiveBallsMoved arena.balls
    connected = true


  everyone.now.pingServer = ->
    console.log "pong"


  everyone.now.getClients = (callback) ->
    db.User.find {}, (err, docs) ->
      callback docs


  everyone.now.authenticate = (user, pw, callback) ->
    db.User.findOne { username: user, password: pw }, (err, u) =>
      if err or not u
        callback { ok: false }
        # Don't disconnect the user (@socket.disconnect())
        # Simply allow them to call authenticate() again.
      else
        log "user #{u.username} authenticated"

        # Connect the nowjs user to the user in our database.
        # This being set marks the user as authenticated.
        # Authorization still needs to be done for every action!
        # TODO do the authorization
        @user.user_model = u

        callback { ok: true }

  everyone.now.getStats = (user, callback) ->
    db.User.findOne { username: user }, (err, u) ->
      callback
        rating: u.rating
        avatarURL: u.avatarURL
        gamesWon: u.gamesWon
        gamesPlayed: u.gamesPlayed
        timePlayed: u.timePlayed
        achievements: u.achievements
        ratingHistory: u.ratingHistory


  everyone.now.logServer = (msg) ->
    console.log msg


  everyone.now.devLogChat = (msg) ->
    console.log "dev log chat message: #{msg}"
    everyone.now.receiveDevLogMessage msg


  everyone.now.assignRoom = (callback) ->

    client = @
    cid = client.user.clientId

    # If the client is in a room, client.user.room_group is set to the corresponding group.

    if (rg = client.user.room_group)?
      # Client is already in a room
      log "user with clientId #{cid} is already in room #{rg.groupName}"
      # Tell user that joining failed
      callback false
    else
      # Find suitable room for client

      # For now, just put the player into the first free room
      # suitable_room_id = (_.keys rooms).some (r) -> not r.empty()
      suitable_room_id = getSuitableRoom()

      # If there is no matching room, create a new one
      room_id = suitable_room_id or allocateNewRoom()
      room = rooms[room_id]

      clients_in_room_before_join = room.getClients()

      log "putting user with clientID #{cid} into room id #{room_id}"
      room.addClient client
      room_group = nowjs.getGroup "room-#{room_id}"
      room_group.addUser cid
      client.user.room_group = room_group

      # Tell user that joining was successful
      callback true, room_id

      # Tell user about who is already in the room
      for c in clients_in_room_before_join
        @now.receivePlayerJoined c.user.user_model

      # Notify other players in the room of joined user
      u = client.user.user_model
      room_group.now.receivePlayerJoined
        # TODO put this "information for other users" into a user model method
        id: u._id
        username: u.username
        rating: u.rating
        avatarURL: u.avatarURL

      # If room is full, tell everyone that the game will start soon and start it after some seconds
      if room.full()
        READY_TIME = config.ready_time_ms

        # Notify that everyone is ready and that the game will start in READY_TIME ms
        room_group.now.receiveRoomReady READY_TIME

        # Start the game after READY_TIME ms
        setTimeout room_group.now.receiveStartGame, READY_TIME


  everyone.now.leaveRoom = (callback) ->
    # TODO implement
    log "leaveRoom not implemented"


  everyone.now.sendChatToRoom = (msg) ->
    client = @
    room_group = client.user.room_group
    if not room_group
      log 'cannot send chat message: client #{client.user.clientId} is not in a room'
    else
      username = client.user.user_model.username
      log 'chat message from #{username} to room #{room_group.groupName}'
      room_group.now.receiveRoomChat username, msg


  everyone.now.setAngle = (player_id, angle) ->
    arena.setAngle player_id, angle
    everyone.now.receiveAngle(player_id, angle)

  everyone.now.usePlayerModels = (callback) ->
    callback arena.players


  everyone.now.startGravityGun = (player_id, x, y) ->
    log "Start Gun"
    # TODO remove X, Y only allow pulling balls in line
    player = arena.players[player_id]

    pullCallback = (pulled_ball) =>
      activateCallback = (powerup_type) =>
        everyone.now.receiveActivatePowerup(player_id, powerup_type)

      deactivateCallback = =>
        player.powerup = null
        everyone.now.receiveDeactivatePowerup(player_id)


      everyone.now.receiveBallMoved pulled_ball, config.pull_time_ms, '<>'
      setTimeout () => # Ball now in turret
        everyone.now.receiveBallInTurret(pulled_ball)
        if pulled_ball.type.kind == config.ball_kinds.powerup
          arena.setPowerup(player, pulled_ball.type.powerup_kind, activateCallback, deactivateCallback)
          fadeOut = true
          everyone.now.receiveMessage player.id, pulled_ball.type.powerup_message, fadeOut

      , config.pull_time_ms

    arena.pull(
      player,
      x,
      y,
      everyone,  # TODO don't do this, use some debug object
      pullCallback,
      => everyone.now.receiveValidPull(player.id),
      => everyone.now.receiveInvalidPull(player.id),
    )


  everyone.now.stopGravityGun = (player_id) ->
    player = arena.players[player_id]
    arena.shoot(
      player
      everyone
      (shot_ball, hit_player) => everyone.now.receiveShot player.id, shot_ball, hit_player.id
      (shot_ball, hit_player) =>
        everyone.now.receiveHealth hit_player.id, hit_player.health
        everyone.now.receiveRemoveBall shot_ball
    )


  everyone.now.usePowerup = (player_id) ->
    arena.usePowerup arena.players[player_id]


createApp = ->
  app = express.createServer()
  app.configure -> app.use express.bodyParser()
  app.listen PORT, ADDRESS
  app

gameOver = ->
  healths = (p.health for p in arena.players)
  max_health = Math.max healths...
  max_healths = (h for h in healths when h == max_health)
  draw = max_healths.length > 1

  log "DRAW?", max_health, max_healths, draw

  # Outcomes are 0=lose, 1=draw, 2=win
  outcomes = {}
  for player in arena.players
    outcomes[player.id] =
      if player.health == max_health
        if draw then 1 else 2
      else
        0

  results = {}
  for player in arena.players
    results[player.id] =
      health: player.health
      outcome: outcomes[player.id]
      points_scored: []
      acheivements_gained: []

  return results


# Start the intervals which control ball rotation and the clock
startTimers = ->
  # Ball Triangle Rotations
  @balls_to_delete = []
  ball_rotation = setInterval () =>
    arena.rotateTriangles(ARENA_SIZE, arena.ball_positions)
    if connected
      everyone.now.receiveBallsMoved(arena.balls, config.rotation_time, 'backOut')

      # TODO: Clean me, use .includes? or something
      for b_id in arena.balls_to_delete
        i = 0
        for b in arena.balls
          if b and b.id == b_id
            everyone.now.receiveRemoveBall(b)
            arena.balls.splice i, 1
          else
            i += 1

      @balls_to_delete = []
  , config.rotation_interval

  # Arena clock time
  seconds = config.game_time
  clock = setInterval () =>
    if connected
      everyone.now.receiveClock --seconds

    if seconds == 0 or arena.aliveCount() <= 1
      clearInterval clock
      clearInterval ball_rotation
      everyone.now.receiveGameOver gameOver()

  , config.clock_interval


run = ->

  app = createApp()

  db.connect()

  everyone = nowjs.initialize(app, { socketio: {'browser client minification': true} })
  configureNow everyone

  startTimers()

run()
