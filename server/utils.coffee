exports.config = require('../config').config


exports.log = (args...) ->
  console.log args...


exports.dir = (obj) ->
  console.log(JSON.stringify obj)


exports.dict = (arr) ->
  d = {}
  for entry in arr
    key = entry[0]
    value = entry[1]
    d[key] = value
  d


exports.even = (num) ->
  num % 2 == 0


exports.degToRad = (deg) ->
  (deg * Math.PI) / 180


exports.radToDeg = (rad) ->
  (rad * 180) / Math.PI


exports.partition = (list, iterator) ->
  take = []
  reject = []
  i = 0
  for x in list
    (if iterator(x, i) then take else reject).push x
    i++
  [take, reject]


exports.flatten = (array) ->
  [].concat.apply([], array)


exports.assert = (bool, msg) ->
  if not bool
    throw new Error('assertion failed' + if msg? then ' ' + msg else '')


exports.negativeMod = (num, div) ->
  tmp = num % div
  if tmp < 0
    div + tmp
  else
    tmp

# Some simple arithmetic tween calculation functions
# format is (frame #, original_val, change_in_value, total_frames)
exports.ServerAnimation =
  easeInOutCubic: (t, b, c, d) ->
    t /= d/2
    if t < 1
      return c/2*t*t*t + b
    t -= 2
    return c/2*(t*t*t + 2) + b

  linearTween: (t, b, c, d) ->
    return c*t/d + b
