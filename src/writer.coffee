{WritableBulk} = require('elasticsearch-streams')
through2 = require 'through2'
byline   = require 'byline'
mixin    = require './mixin'

OPERS = ['index', 'delete', 'update', 'create']

fromJson = ->
    saved = null # index are saved with next
    through2.obj (line, enc, callback) ->
        json = JSON.parse(line)
        if saved != null
            this.push saved
            this.push json
            saved = null
        else if json.index
            saved = json
        else
            this.push json
        callback()

toDoc = ->
    d = (oper, source) ->
        opername = OPERS.find (o) -> oper[o]
        head = oper[opername]
        mixin head, _oper:opername, _source:source
    saved = null
    through2.obj (row, enc, callback) ->
        if saved
            this.push d(saved, row)
            saved = null
        else
            if row.index or row.create
                saved = row
            else
                this.push d(row)
        callback()

transform = (operdelete, trans, index, type) ->
    through2.obj (row, enc, callback) ->
        t = trans(row)
        t._oper = 'delete' if operdelete
        oper = {}
        oper[t._oper] = {_id:t._id, _index:(index ? t._index), _type:(type ? t._type)}
        this.push oper
        if t._oper in ['index', 'create']
            this.push t._source
        callback()

module.exports = (client, _opts, operdelete, trans, instream) ->

    bulkExec = (bulk, callback) ->
        opts = mixin _opts, body:bulk
        client.bulk opts, (err, res) ->
            if res.errors
                # { index: { _index: 'blah', _type: 'ttninjs', _id: 'sdltb459b78', status: 400,
                #   error: { type: 'mapper_parsing_exception',
                #            reason: 'Field name [sdl.archivedBy] cannot contain \'.\''
                #            } } }
                oper = OPERS.find (oper) -> res.items[0]?[oper]
                reason = res.items[0]?[oper]?.error?.reason
                if reason
                    callback new Error(reason)
                else
                    callback err
            else
                callback null, res

    instream
    .pipe byline.createStream() # ensure we get whole lines
    .pipe fromJson()
    .pipe toDoc()
    .pipe transform(operdelete, trans, _opts.index, _opts.type)
    .pipe new WritableBulk(bulkExec)
