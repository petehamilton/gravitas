# 2D vectors and segments

length = (v) ->
  Math.sqrt(v.x * v.x + v.y * v.y)

scale = (v, s) ->
  x: v.x * s
  y: v.y * s

normed = (v) ->
  l = length v
  throw new Error("normed: nullvector cannot be normed") if l == 0
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

# Checks if two segments intersect.
#
# Returns:
# {
#   intersects:         true iff the segments overlap
#   intersection_point: the point in which their lines overlap (even if intersects == false)
# }
#
# For parallel, non-overlapping lines:
# {
#   intersects:         false
#   intersection_point: null
# }
#
# For parallel, overlapping (collinear) lines:
# {
#   intersects:         true
#   intersection_point: null
# }
sect = (s1, s2) ->
  # from http://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect
  # t: (q − p) × s / (r × s)
  # u: (q − p) × r / (r × s)
  # Intersect <-> 0 <= t,u <= 1
  [p, q, r, s] = [s1.s, s2.s, s1.d, s2.d]

  r_x_s = cross r, s

  E = 0.0001

  if -E < r_x_s < E
    # Parallel
    # TODO tests for parallel and collinear
    collinear = (cross (diff q, p), r) == 0
    return {
      intersects: collinear
      point: null
    }
  else
    t = (cross (diff q, p), s) / r_x_s
    u = (cross (diff q, p), r) / r_x_s

    return {
      intersects: 0 <= t <= 1 and 0 <= u <= 1
      point:  # p + t * r
        x: p.x + t * r.x
        y: p.y + t * r.y
    }


exports = {
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

@intersect = exports; module?.exports = exports
