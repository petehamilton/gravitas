http = require 'http'
express = require 'express'
nowjs = require 'now'
assert = require 'assert'
path = require 'path'
_ = require './lib/underscore'
arena_model = require './arena_model'
pbm = require './ball_model'
spm = require './shield_powerup_model'
db = require './db'
{ log, dir, ServerAnimation, roundNumber } = require './common/utils'
config = require('../config').config


# Server configuration

PORT = 8000
ADDRESS = "0.0.0.0"
MODEL_FPS = config.model_fps
BALLS_ENABLED = config.balls_enabled
ARENA_SIZE = config.arena_size

# Global Variables

everyone = null

connected = false


# Available game rooms. Key: room ID
rooms = {}
next_room_id = 0



removeFromRoom = (client, callback) ->
  cid = client.user.clientId

  # If the client is in a room, client.user.room_group is set to the corresponding group.

  unless client.user.room_group?
    # Client is not in a room
    log "user with clientId #{cid} is not in a room, so they cannot leave"
    # Tell user that leaving failed
    callback false
  else
    # Client is in a room
    { room, room_group } = client.user

    log "user with clientId #{cid} is leaving room group #{room_group.groupName}"

    # Remove user from room
    room.removeClient client
    room_group.removeUser cid
    delete client.user.room
    delete client.user.room_group

    # Tell user that leaving was successful
    callback true

    u = client.user.user_model
    # Tell the other room members that the user left
    room_group.now.receivePlayerLeft
      # TODO put this "information for other users" into a user model method
      id: u._id



class Room
  constructor: ->
    # Stores nowjs clients (the User class, not the User#user namespace)
    # We call them "client" througout this class to avoid confusion with User.user and our DB User
    # Note that "client" instances are not the same objects across calls!
    @_clients = [ null, null, null, null ]
    @_num_clients = 0
    @_open = true
    # @arena = null

  getClients: ->
    _.filter @_clients, (c) -> c != null

  getClientIndex: (client) ->
    # Note that "client" instances are not the same objects across calls!
    for c, i in @_clients when (c != null and c.user.clientId == client.user.clientId)
      return i
    throw new Error("room doesn't contain clientId #{client.user.clientId}!")

  addClient: (client) ->
    # Note that "client" instances are not the same objects across calls!
    # TODO highlevel this with underscore
    for c, i in @_clients when c == null
      @_clients[i] = client
      @_num_clients++
      return
    throw new Error('room is full!')

  removeClient: (client) ->
    # Note that "client" instances are not the same objects across calls!
    i = @getClientIndex client
    @_clients[i] = null
    @_num_clients--

  full: ->
    @_num_clients == @_clients.length

  isOpen: ->
    @_open

  close: ->
    @_open = false

  # TODO Pull out the network stuff
  startArena: (room_group, userIdToPlayerIdMapping, userIdToUsernameMapping) ->
    # @arena = new arena_model.ArenaModel()
    arena = new arena_model.ArenaModel()

    room_now = room_group.now
    assert.ok(room_now, "room_now is not defined")

    @setupArenaRpcs arena, room_now

    log "telling clients of room #{room_group.groupName} to start game with player mapping", JSON.stringify(userIdToPlayerIdMapping)

    room_group.now.receiveStartGame userIdToPlayerIdMapping, userIdToUsernameMapping

    # Send initial ball positions
    # TODO send other initial game data?
    room_now.receiveBallsMoved arena.balls

    @startTimers arena, room_now


  setupArenaRpcs: (arena, room_now) ->
    ### ARENA RPCS ###

    room_now.setAngle = (player_id, angle) ->
      arena.setAngle player_id, angle
      room_now.receiveAngle(player_id, angle)


    room_now.usePlayerModels = (callback) ->
      callback arena.players


    room_now.startGravityGun = (player_id, x, y) ->
      log "Start Gun"
      # TODO remove X, Y, use model angle only
      player = arena.players[player_id]

      pullCallback = (pulled_ball) =>
        activateCallback = (powerup_type) =>
          room_now.receiveActivatePowerup(player_id, powerup_type)

        deactivateCallback = =>
          player.powerup = null
          room_now.receiveDeactivatePowerup(player_id)


        room_now.receiveBallMoved pulled_ball, config.pull_time_ms, '<>'
        setTimeout () => # Ball now in turret
          room_now.receiveBallInTurret(pulled_ball)
          if pulled_ball.type.kind == config.ball_kinds.powerup
            arena.setPowerup(player, pulled_ball.type.powerup_kind, activateCallback, deactivateCallback)
            fadeOut = true
            room_now.receiveMessage player.id, pulled_ball.type.powerup_message, fadeOut

        , config.pull_time_ms

      arena.pull(
        player,
        x,
        y,
        room_now,  # TODO don't do this, use some debug object
        pullCallback,
        => room_now.receiveValidPull(player.id),
        => room_now.receiveInvalidPull(player.id),
      )


    room_now.stopGravityGun = (player_id) ->
      player = arena.players[player_id]
      arena.shoot(
        player
        room_now
        (shot_ball, hit_player) => room_now.receiveShot player.id, shot_ball, hit_player.id
        (shot_ball, hit_player) =>
          room_now.receiveHealth hit_player.id, hit_player.health
          room_now.receiveRemoveBall shot_ball
      )


    room_now.usePowerup = (player_id) ->
      arena.usePowerup arena.players[player_id]

  calculateNewRating: (userRating, enemyRating1, enemyRating2, enemyRating3, won) =>
        allyTeamRating = userRating
        enemyTeamRating = ((enemyRating1 + enemyRating2 + enemyRating3) / 3)
        winChance = @calculateWinChance(allyTeamRating,enemyTeamRating)
        Math.floor(userRating + 32 * ( (if won then 1 else 0) - winChance))


  calculateWinChance: (allyTeamRating, enemyTeamRating) ->
        1 / (1 + Math.pow(10, ((enemyTeamRating - allyTeamRating) / 400)))

  gameOver: (arena, room_now, play_time_s) ->
    healths = (p.health for p in arena.players)
    winner_health = Math.max healths...
    draw = (h for h in healths when h == winner_health).length > 1

    { win: WIN, loss: LOSS, draw: DRAW } = config.outcome

    outcomes = {}
    places = {}

    place = 1
    for player in arena.players
      outcomes[player.id] =
        if player.health == winner_health
          if draw then DRAW else WIN
        else
          LOSS

      places[player.id] = if player.health == winner_health then 1 else place
      place += 1

    # Present new achievements
    possible_achievements = [1,2,3,4,5,6] #TODO, get me from database
    achievements = {}
    # TODO fix bug
    # for player in arena.players
    #   achievements[player.id] = []
    #   for achievement in possible_achievements
    #     # TODO: Only if earned!
    #     unless achievement not in player.achievements
    #       # TODO: Give achievement to player

    #       # Add achievement to list for client presentation
    #       achievements[player.id].push achievement

    # Gather ratings
    ratings = {}
    for player in arena.players
      ratings[player.id] = @_clients[player.id].user.user_model.rating


    # Calculate rating changes
    new_ratings = {}
    for player in arena.players
      player_rating = ratings[player.id]
      other_ratings = (ratings[p.id] for p in arena.players when p.id != player.id)
      new_ratings[player.id] = @calculateNewRating(player_rating,
                                                   other_ratings[0],
                                                   other_ratings[1],
                                                   other_ratings[2],
                                                   outcomes[player.id] == WIN
                                                  )

    # Gather results
    results = {}
    for player in arena.players
      user = @_clients[player.id].user.user_model

      results[player.id] =
        id: user._id
        username: user.username
        health: player.health
        outcome: outcomes[player.id]
        place: places[player.id]
        avatarURL: user.avatarURL
        rating: new_ratings[player.id]
        rating_change: new_ratings[player.id] - ratings[player.id]
        achievements_gained: achievements[player.id]


    # Update statistics in database
    for player in arena.players
      pid = player.id
      user = @_clients[pid].user.user_model

      # Time played
      user.timePlayed_s += play_time_s

      # Rating
      user.rating = new_ratings[pid]

      # Played games
      user.gamesPlayed++
      switch results[pid].outcome
        when WIN then user.gamesWon++
        when LOSS then user.gamesLost++

      user.save()

    return results


  # Start the intervals which control ball rotation and the clock
  startTimers: (arena, room_now) ->
    # Ball Triangle Rotations
    @balls_to_delete = []
    ball_rotation = setInterval () =>
      arena.rotateTriangles(ARENA_SIZE, arena.ball_positions)
      if connected
        room_now.receiveBallsMoved(arena.balls, config.rotation_time, 'backOut')

        # TODO: Clean me, use .includes? or something
        for b_id in arena.balls_to_delete
          i = 0
          for b in arena.balls
            if b and b.id == b_id
              room_now.receiveRemoveBall(b)
              arena.balls.splice i, 1
            else
              i += 1

        @balls_to_delete = []
    , config.rotation_interval

    # Arena clock time
    seconds = config.game_time_s
    clock = setInterval () =>
      if connected
        room_now.receiveClock --seconds

      if seconds == 0 or arena.aliveCount() <= 1
        # Game is finished
        log "game over"
        clearInterval clock
        clearInterval ball_rotation
        play_time_s = config.game_time_s - seconds
        results = @gameOver arena, room_now, play_time_s
        room_now.receiveGameOver results

        log "booting players from room to allow rejoin"
        # Remove all players from the room so that they can join another one
        for player in arena.players
          client = @_clients[player.id]
          removeFromRoom client, (ok) => assert.ok(ok, "client should be removed after game")

    , config.clock_interval


# Creates a new room, adds it to the available rooms and returns the room ID
allocateNewRoom = ->
  id = next_room_id++
  rooms[id] = new Room()
  id


# TODO allocate room based on player skills
getSuitableRoom = ->
  for id, r of rooms
    if not r.full() and r.isOpen()
      return id
  null


startRoomGame = (room, room_group) ->
  userIdToPlayerIdMapping = {}
  userIdToUsernameMapping = {}
  playerIdToUserIdMapping = {}

  clients = room.getClients()
  assert.ok(clients.length == 4, "game started with != 4 players")

  for c, pid in clients
    u = c.user.user_model
    assert.ok(u, "user model is defined when starting game")
    playerIdToUserIdMapping[pid] = u._id
    userIdToPlayerIdMapping[u._id] = pid
    userIdToUsernameMapping[u._id] = u.username

  # Start a new game for these players
  room.startArena room_group, userIdToPlayerIdMapping, userIdToUsernameMapping


configureNow = (everyone) ->

  nowjs.on 'connect', ->
    console.log "client #{@user.clientId} connected"
    # TODO check this
    connected = true

  nowjs.on 'disconnect', ->
    console.log "client #{@user.clientId} disconnected"

    # If the client is in a room, remove them
    removeFromRoom @, (was_removed) => log "removed disconnected client from room: #{was_removed}"

    # TODO remove them from running games


  ### GLOBAL RPCS ###

  everyone.now.pingServer = (callback) ->
    console.log "pong"
    setTimeout (=> callback?()), 500


  everyone.now.getClients = (callback) ->
    db.User.find {}, (err, docs) ->
      callback docs


  everyone.now.authenticate = (user, pw, callback) ->
    db.User.findOne { username: user, password: pw }, (err, u) =>
      if err or not u
        callback false
        # Don't disconnect the user (@socket.disconnect())
        # Simply allow them to call authenticate() again.
      else
        log "user #{u.username} authenticated"

        # Connect the nowjs user to the user in our database.
        # This being set marks the user as authenticated.
        # Authorization still needs to be done for every action!
        # TODO do the authorization
        @user.user_model = u

        callback true, u._id

  everyone.now.getStats = (user, callback) ->
    db.User.findOne { username: user }, (err, u) ->
      callback
        rating: u.rating
        avatarURL: u.avatarURL
        gamesWon: u.gamesWon
        gamesPlayed: u.gamesPlayed
        timePlayed_s: u.timePlayed_s
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

    # If the client is in a room, client.user.room and client.user.room_group are set.

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
      client.user.room = room
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

        # Close the room so that no more players can
        room.close()

        # Notify that everyone is ready and that the game will start in READY_TIME ms
        room_group.now.receiveRoomReady READY_TIME

        # Start the game after READY_TIME ms
        setTimeout (=> startRoomGame room, room_group), READY_TIME


  everyone.now.leaveRoom = (callback) ->
    removeFromRoom @, callback

    capitaliseFirstLetter = (string) ->
      string.charAt(0).toUpperCase() + string.slice(1)

  everyone.now.sendChatToRoom = (msg) ->
    client = @
    room_group = client.user.room_group
    if not room_group
      log 'cannot send chat message: client #{client.user.clientId} is not in a room'
    else
      username = client.user.user_model.username
      username = username.charAt(0).toUpperCase() + username.slice(1)
      log 'chat message from #{username} to room #{room_group.groupName}'
      room_group.now.receiveRoomChat username, msg





createApp = ->
  app = express.createServer()
  app.configure ->
    # app.use express.methodOverride()
    app.use express.bodyParser()
    # app.use app.router
    client_path = path.join(path.dirname(__dirname), 'client')
    log "serving static files from #{client_path}"
    app.use '/', express.static(client_path)
    # app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))

  app.get '/reset', (req, res) =>
    log "rooms", rooms
    log "resetting"
    rooms = {}
    log "rooms", rooms
    next_room_id = 0
    res.send "resetted"

  app.listen PORT, ADDRESS
  app


run = ->

  app = createApp()

  log "connecting to the database"
  db.connect (err) ->
    if err
      console.error(err)
      process.exit(1)

  everyone = nowjs.initialize(app, { socketio: {'browser client minification': true} })
  configureNow everyone

run()
