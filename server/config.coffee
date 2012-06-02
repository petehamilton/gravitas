config =

  game:
    model_fps: 30
    player_ids: [0..3]

  ball_kinds:
    player: 0
    powerup: 1

  powerup_effects:
    health: 0
    shield: 1

  # TODO flatten out the config a bit
  arena:
    size:
      x: 400
      y: 400

    balls_enabled: true

    ball_mass: 1
    ball_size: 40
    vortex_mass: 10000

    # Maximum allowed ball velocity
    terminal_velocity: 5


exports.config = config
