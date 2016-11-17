{ReadableSearch} = require('elasticsearch-streams')
through2 = require 'through2'
mixin    = require './mixin'

toBulk = -> through2.obj (doc, enc, callback) ->
    this.push index:{_index: doc._index, _type:doc._type, _id:doc._id}
    this.push doc._source
    callback()

jsonStream = -> through2.obj (chunk, enc, callback) ->
    this.push(JSON.stringify(chunk) + "\n")
    callback()

module.exports = (client, _opts) ->

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

    (new ReadableSearch(scrollExec)).pipe(toBulk()).pipe(jsonStream())
