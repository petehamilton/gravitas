config =
  fps: 50

  ball_kinds:
    player: 0
    powerup: 1

  powerup_effects:
    health: 0
    shield: 1

  # Game Information
  model_fps: 30
  player_ids: [0..3]

  arena_size:
    x: 600
    y: 600

  balls_enabled: true

  ball_size: 40

  crosshair_size: 64

  vortex_mass: 10000

  turret_width: 200
  turret_height: 100

  hp_radius: 10
  max_health: 100

  lag_limit: 50

  #TODO: rename these to something better
  # radius of circle balls allowed within
  dist_between_balls: 60

  # Number of different levels in 'orbit'
  ball_levels: 3


if exports?
  exports.config = config
else
  @config = config
