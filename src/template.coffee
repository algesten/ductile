through2 = require 'through2'
mixin    = require './mixin'


toBulk = -> through2.obj (doc, enc, callback) ->
    this.push template:doc
    callback()


jsonStream = -> through2.obj (chunk, enc, callback) ->
    this.push(JSON.stringify(chunk) + "\n")
    callback()


module.exports = (client, _opts) ->

    opts = mixin _opts

    instream = toBulk()
    sink = instream.write.bind instream

    exec = ->
        client.indices.getTemplate(opts).then (v) ->
            {_name:name, _template:template} for name, template of v

    exec().then (docs) ->
        docs.forEach sink
    .catch (err) ->
        stream.emit 'error', err

    stream = instream.pipe jsonStream()
