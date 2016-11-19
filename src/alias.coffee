through2 = require 'through2'
mixin    = require './mixin'

flatten = (a) -> [].concat.apply [], a


toBulk = -> through2.obj (doc, enc, callback) ->
    this.push alias:doc
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
            col = {}
            vs.map (v) -> for i, {aliases} of v
                for n of aliases
                    (col[n] = (col[n] ? [])).push i
            {_name, _index:(if i.length == 1 then i[0] else i)} for _name, i of col

    exec().then (docs) ->
        docs.forEach sink
    .catch (err) ->
        stream.emit 'error', err

    stream = instream.pipe jsonStream()
