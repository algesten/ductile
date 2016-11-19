through2 = require 'through2'
mixin    = require './mixin'


flatten = (a) -> [].concat.apply [], a


toBulk = -> through2.obj (doc, enc, callback) ->
    this.push mapping:doc
    callback()


jsonStream = -> through2.obj (chunk, enc, callback) ->
    this.push(JSON.stringify(chunk) + "\n")
    callback()


module.exports = (client, _opts) ->

    opts = mixin _opts

    instream = toBulk()
    sink = instream.write.bind instream

    exec = ->
        client.indices.getMapping(opts).then (v) ->
            for index, {mappings} of v
                for type, mapping of mappings
                    {_index:index, _type:type, _mapping:mapping}
        .then flatten

    exec().then (docs) ->
        docs.forEach sink
    .catch (err) ->
        stream.emit 'error', err

    stream = instream.pipe jsonStream()
