TURRET_WIDTH = 100
TURRET_HEIGHT = 50
CANVAS_WIDTH = 600
CANVAS_HEIGHT = 600
PLAYER_CENTER_OFFSET_X = 100
PLAYER_CENTER_OFFSET_Y = 100

FPS = 50

config =
  # Used for animations etc
  fps: FPS

  # Upper limit for processing mouse move events
  mouse_move_fps: 30

  ball_kinds:
    player: 0
    powerup: 1

  # Powerup effects, when you add a new one increase powerup_count below
  powerup_kinds:
    shield: 0
    health: 1

  # TODO is there a better way to do this
  powerup_count: 2

  powerup_messages:
    shield: "Shield powerup!\nPress space to activate."
    health: "Full health powerup!\nPress space to activate."

  # Probability of spawning a powerup
  powerup_probability: 0.5

  # Game Information
  player_ids: [0..3]

  arena_size:
    x: CANVAS_WIDTH
    y: CANVAS_HEIGHT

  balls_enabled: true

  ball_size: 40

  crosshair_size: 64
  pull_radius: 20
  pull_time_ms: 300
  shoot_time_ms: 300

  turret_width: TURRET_WIDTH
  turret_height: TURRET_HEIGHT

  # The offset of the turret picture for the corners.
  turret_offset:
    x: 30
    y: TURRET_HEIGHT/2

  # Max health for each player
  max_health: 1
  health_decimal_places: 2 # Number of decimal places player health is allowed

  lag_limit: 50

  #TODO: rename these to something better
  # radius of circle balls allowed within
  dist_between_balls: 60

  # Number of different levels in 'orbit'
  ball_levels: 3
  rotation_interval: 1000 # Milliseconds between ball rotations
  rotation_time: 500 # Milliseconds to rotate balls

  # Time for game rounds in seconds
  game_time_s: 180

  # Milliseconds between ticks (i.e. 1 second)
  clock_interval: 1000

  # Player Centers, used for ball pulling, turret rotation etc
  player_centers:
    0: { x: PLAYER_CENTER_OFFSET_X, y: PLAYER_CENTER_OFFSET_Y }
    1: { x: CANVAS_WIDTH - PLAYER_CENTER_OFFSET_X, y: PLAYER_CENTER_OFFSET_Y }
    2: { x: CANVAS_WIDTH - PLAYER_CENTER_OFFSET_X, y: CANVAS_HEIGHT - PLAYER_CENTER_OFFSET_Y }
    3: { x: PLAYER_CENTER_OFFSET_X, y: CANVAS_HEIGHT - PLAYER_CENTER_OFFSET_Y }

  turret_pulse_interval: 3000
  collision_check_interval: FPS

  shield_radius: 80
  shield_damage_speed: 500
  survivable_hits: 3
  hit_damage: 0.1

  outcome:
    win: 0
    loss: 1
    draw: 2

  post_game_wait: 3000 # Time to pause after a game

  player_colours:
    0: "#00a2ff"
    1: "#72ff00"
    2: "#fc00ff"
    3: "#fcff00"

  warning_colour: "#ff0000"

  # Default users with passwords
  default_users:
    niklas:
      pass:   'niklas'
      avatar: 'https://dl.dropbox.com/u/5718548/gravitas_profiles/niklas.png'
    lukasz:
      pass:   'lukasz'
      avatar: 'https://dl.dropbox.com/u/5718548/gravitas_profiles/lucas.png'
    peter:
      pass:   'peter'
      avatar: 'https://dl.dropbox.com/u/5718548/gravitas_profiles/pete.png'
    sarah:
      pass:   'sarah'
      avatar: 'https://dl.dropbox.com/u/5718548/gravitas_profiles/sarah.png'
    mark:
      pass:   'mark'
      avatar: 'https://dl.dropbox.com/u/5718548/gravitas_profiles/mark.png'
    x:
      pass:   'x'
      avatar: 'http://amix.dk/uploads/coffeescript.jpg'

  # Length of countdown between a lobby room becoming full and the start of the game
  ready_time_ms: 3000


if exports?
  exports.config = config
else
  @config = config
