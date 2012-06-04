{ config, even, degToRad } = require './utils'
pbm = require './ball_model'


PLAYER_IDS = config.player_ids
BALL_SIZE = config.ball_size
ARENA_SIZE = config.arena_size
BALL_LEVELS = config.ball_levels


next_ball_id = 0
genBallId = -> next_ball_id++

cur_player_index = 0
# Loops around player Id's
nextPlayerId = ->
  tmp = PLAYER_IDS[cur_player_index++]
  cur_player_index %= PLAYER_IDS.length
  tmp


class @ArenaModel

  constructor: ->
    starting_coords = @calculateStartPoints()
    @balls = for {x, y} in starting_coords
      new pbm.BallModel genBallId(), pbm.makePlayerBallType(nextPlayerId()), x, y

  # Calculates starting points for all the balls
  calculateStartPoints: ->

    # Calculates the number of balls for a given row
    ballsForRow = (row) ->
      max_index = BALL_LEVELS - 1
      offset = Math.abs (max_index - row)
      max_index - offset + BALL_LEVELS

    dist_between_balls = config.dist_between_balls
    dist_components = {dx: dist_between_balls / 2, dy: Math.sin(degToRad(60)) * dist_between_balls}
    center_point = { x: ARENA_SIZE.x/2, y: ARENA_SIZE.y/2 }

    start_coords = []
    rows = BALL_LEVELS * 2 - 1

    for row in [0..(rows-1)]
      cols = ballsForRow row
      rows_from_center = Math.abs(BALL_LEVELS - 1 - row)

      for col in [0..cols-1]
        start_coords.push
          # TODO style
          x : center_point.x +
              (col - Math.floor(cols / 2)) * dist_between_balls +
              if even cols
                dist_components.dx
              else
                0
          y : Math.round (center_point.y + dist_components.dy * (row - Math.floor(rows / 2)))

    return start_coords
