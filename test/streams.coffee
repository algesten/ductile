streamBuffers = require('stream-buffers')
fs = require 'fs'

module.exports =
    empty:  -> fs.createReadStream(__dirname + '/empty')
    bulk:   -> fs.createReadStream(__dirname + '/test.bulk')
    output: -> new streamBuffers.WritableStreamBuffer()
    string:  (out) -> out.getContentsAsString('utf8')
    promise: (out) -> new Promise (rs) ->
        cb = -> rs out.getContentsAsString?('utf8') ? null
        out.on 'finish', cb
        out.on 'end', cb
