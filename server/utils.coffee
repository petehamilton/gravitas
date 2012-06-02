exports.config = require('../config').config

exports.log = (args...) -> console.log args...

exports.dir = (obj) -> console.log(JSON.stringify obj)
