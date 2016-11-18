through2 = require 'through2'
mixin    = require './mixin'

flatten = (a) -> [].concat.apply [], a


toBulk = -> through2.obj (doc, enc, callback) ->
    this.push alias:{_index:doc._index, _name:doc._name}
    callback()


jsonStream = -> through2.obj (chunk, enc, callback) ->
    this.push(JSON.stringify(chunk) + "\n")
    callback()


module.exports = (client, _opts) ->

    opts = mixin _opts

    instream = toBulk()
    sink = instream.write.bind instream

    exec = ->
        client.indices.getAlias(opts).then (v) ->
            index for index, {aliases} of v
        .then (indices) ->
            Promise.all indices.map (index) -> client.indices.getAlias {index}
        .then (vs) ->
            flatten flatten vs.map (v) ->
                {_index, _name} for _name of aliases for _index, {aliases} of v

    exec().then (docs) ->
        docs.forEach sink
    .catch (err) ->
        stream.emit 'error', err

    stream = instream.pipe jsonStream()
