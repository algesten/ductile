{ReadableSearch} = require('elasticsearch-streams')
through2 = require 'through2'
mixin    = require './mixin'

toBulk = (operdelete) -> through2.obj (doc, enc, callback) ->
    idx = {_index: doc._index, _type:doc._type, _id:doc._id}
    if operdelete
        this.push delete:idx
    else
        this.push index:idx
        this.push doc._source
    callback()

transform = (fn) -> through2.obj (doc, enc, callback) ->
    tdoc = fn(doc)
    if tdoc
        this.push tdoc
    callback()

jsonStream = -> through2.obj (chunk, enc, callback) ->
    this.push(JSON.stringify(chunk) + "\n")
    callback()


module.exports = (client, _opts, operdelete, trans) ->

    opts = mixin _opts, {scroll:'60s'}

    # need some kind of query
    if !opts.body and !opts.q
        opts.body = query:match_all:{}

    # body wins over q, not both at the same time
    if opts.body
        delete opts.q
    else
        delete opts.body

    scrollExec = do ->
        scrollId = null
        (from, callback) ->
            if scrollId
                client.scroll({scrollId, scroll:'60s'}, callback)
            else
                client.search opts, (err, res) ->
                    scrollId = res?._scroll_id
                    callback(err, res)

    readable = new ReadableSearch scrollExec
    .on 'error', (err) ->
        stream.emit 'error', err

    last = -1

    stream = readable
    .pipe transform(trans)
    .pipe through2.obj (hit, enc, callback) ->
        this.push hit
        if readable.from != last
            last = readable.from
            stream.emit 'progress', {from:last, total:readable.total}
        callback()
    .pipe toBulk(operdelete)
    .pipe jsonStream()
    .on 'end', ->
        if readable.from != last
            stream.emit 'progress', {from:readable.total, total:readable.total}

    stream
