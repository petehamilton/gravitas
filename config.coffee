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
    x: 400
    y: 400

  balls_enabled: true

  ball_mass: 1
  ball_size: 40

  vortex_mass: 10000

  turret_width: 200
  turret_height: 100

  # Maximum allowed ball velocity
  ball_terminal_velocity: 5


if exports?
  exports.config = config
else
  @config = config
