through2 = require 'through2'
mixin    = require './mixin'


toBulk = -> through2.obj (doc, enc, callback) ->
    this.push settings:doc
    callback()


jsonStream = -> through2.obj (chunk, enc, callback) ->
    this.push(JSON.stringify(chunk) + "\n")
    callback()


module.exports = (client, _opts) ->

    opts = mixin _opts

    instream = toBulk()
    sink = instream.write.bind instream

    exec = ->
        client.indices.getSettings(opts).then (v) ->
            for index, {settings} of v
                delete settings.index.uuid
                delete settings.index.version
                delete settings.index.creation_date
                # analysis is inside index for some reason
                if settings.index?.analysis
                    settings.analysis = settings.index.analysis
                    delete settings.index.analysis
                {_index:index, _settings:settings}

    exec().then (docs) ->
        docs.forEach sink
    .catch (err) ->
        stream.emit 'error', err

    stream = instream.pipe jsonStream()
