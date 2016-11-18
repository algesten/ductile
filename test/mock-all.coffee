
module.exports = ->

    es = null

    decache './mock-es'
    mock '../src/es', es = require './mock-es'

    {es}
