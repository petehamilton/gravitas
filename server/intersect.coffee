{ log } = require './utils'
assert = require 'assert'


length = (v) ->
  Math.sqrt(v.x * v.x + v.y * v.y)

scale = (v, s) ->
  x: v.x * s
  y: v.y * s

normed = (v) ->
  l = length v
  assert.ok(l > 0, "norm: length > 0")
  scale(v, 1 / l)

normal = (dv) ->
  # "left-rotated"
  x: -dv.y
  y: dv.x

diff = (a, b) ->
  x: a.x - b.x
  y: a.y - b.y

cross = (a, b) ->
  a.x * b.y - a.y * b.x

# TODO explain that s + d is "the end point"
makeSegment = (x, y, dx, dy) ->
  s:
    x: x
    y: y
  d:
    x: dx
    y: dy

makeSegmentBetween = (x, y, end_x, end_y) ->
  makeSegment x, y, (end_x - x), (end_y - y)

makeSegmentBetweenPoints = (p, q) ->
  makeSegmentBetween p.x, p.y, q.x, q.y

# TODO doc
# see http://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect
sect = (s1, s2) ->
  # t = (q − p) × s / (r × s)
  # u = (q − p) × r / (r × s)
  # Intersect <-> 0 <= t,u <= 1
  [p, q, r, s] = [s1.s, s2.s, s1.d, s2.d]

  r_x_s = cross r, s
  # TODO remove
  # log "r_x_s", r_x_s
  E = 0.0001
  if -E < r_x_s < E
    # Parallel
    null
    # TODO check and return info if collinear
  else
    # TODO remove
    # log "diff q, p:", (diff q, p)
    # log "cross (diff q, p), s:", (cross (diff q, p), s)
    t = (cross (diff q, p), s) / r_x_s
    u = (cross (diff q, p), r) / r_x_s
    # log "t", t

    # ip = p + t * r
    intersect_point =
      x: p.x + t * r.x
      y: p.y + t * r.y
    if 0 <= t <= 1 and 0 <= u <= 1
      # Intersection inside the segments
      # TODO remove
      # log "intersect"
      intersect_point
    else
      # TODO remove
      # log "intersect outside"
      null
      # Intersection of the lines, but outside the segments

module.exports = {
  length
  scale
  normed
  normal
  diff
  cross
  makeSegment
  makeSegmentBetween
  makeSegmentBetweenPoints
  sect
}
