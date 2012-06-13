
log = (args...) -> console.log args...


dir = (obj) -> console.log(JSON.stringify obj)


dict = (arr) ->
  d = {}
  for key, value in arr
    d[key] = value
  d


even = (num) -> num % 2 == 0


degToRad = (deg) -> (deg * Math.PI) / 180


partition = (list, iterator) ->
  take = []
  reject = []
  i = 0
  for x in list
    (if iterator(x, i) then take else reject).push x
    i++
  [take, reject]


flatten = (array) ->
  [].concat.apply([], array)


assert = (bool, msg) ->
  if not bool
    throw new Error('assertion failed' + if msg? then ' ' + msg else '')


negativeMod = (num, div) ->
  tmp = num % div
  if tmp < 0
    div + tmp
  else
    tmp


exports = {
  log
  dir
  dict
  even
  degToRad
  partition
  flatten
  assert
  negativeMod
}

@utils = exports; module?.exports = exports
