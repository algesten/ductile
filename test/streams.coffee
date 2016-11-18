streamBuffers = require('stream-buffers')
fs = require 'fs'

module.exports =
    empty:  -> fs.createReadStream(__dirname + '/empty')
    output: -> new streamBuffers.WritableStreamBuffer()
    string:  (out) -> out.getContentsAsString('utf8')
    promise: (out) -> new Promise (rs) ->
        out.on 'finish', ->
            rs out.getContentsAsString('utf8')
