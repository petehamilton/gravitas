exports.config = require('../config').config

exports.log = (args...) -> console.log args...

exports.dir = (obj) -> console.log(JSON.stringify obj)

exports.dict = (arr) ->
  d = {}
  for key, value in arr
    d[key] = value
  d

exports.even = (num) -> num % 2 == 0

exports.degToRad = (deg) -> (deg * Math.PI) / 180

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
