streamBuffers = require('stream-buffers')
fs = require 'fs'

module.exports =
    empty:  -> fs.createReadStream(__dirname + '/empty')
    bulk:   -> fs.createReadStream(__dirname + '/test.bulk')
    u0085:  -> fs.createReadStream(__dirname + '/bad-u0085.bulk')
    output: -> new streamBuffers.WritableStreamBuffer()
    string:  (out) -> out.getContentsAsString('utf8')
    promise: (stream) -> new Promise (rs) ->
        cb = -> rs stream.getContentsAsString?('utf8') ? null
        stream.on 'finish', cb
        stream.on 'end', cb
