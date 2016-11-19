WritableBulk = require './writable-bulk'
through2 = require 'through2'
byline   = require 'byline'
mixin    = require './mixin'

isTwoRow = (t) ->
    if typeof t == 'string'
        t in ['index', 'update', 'create']
    else
        t.index or t.update or t.create

OPERS = ['index', 'update', 'create', 'delete', 'alias', 'mapping']

# test if bulk contains any non-standard bulk operations (alias or mapping)
isNonStandard = (bulk) ->
    return true for b in bulk when b.alias or b.mapping
    false


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
            if isTwoRow(row)
                saved = row
            else
                this.push d(row)
        callback()

transform = (operdelete, trans, index, type) ->
    through2.obj (row, enc, callback) ->
        if t = trans(row)
            t._oper = 'delete' if operdelete
            oper = {}
            if t._oper == 'alias'
                oper.alias = {_name:t._name, _index:t._index}
            else if t._oper == 'mapping'
                oper.mapping =
                    {_index:(index ? t._index), _type:(type ? t._type), _mapping:t._mapping}
            else
                oper[t._oper] = {_id:t._id, _index:(index ? t._index), _type:(type ? t._type)}
            this.push oper
            if isTwoRow(t._oper)
                this.push t._source
        callback()

module.exports = (client, _opts, operdelete, trans, instream) ->

    writeAlias = (bulk, callback) ->
        bulk.reduce (p, c) ->
            p.then -> pay = c.alias; client.indices.putAlias {name:pay._name, index:pay._index}
        , Promise.resolve()
        .then ->
            callback null, {}
        .catch (err) ->
            callback err

    writeMapping = (bulk, callback) ->
        bulk.reduce (p, c) ->
            p.then -> client.indices.putMapping {index:c._index, type:c._type, body:c._mapping}
        , Promise.resolve()
        .then ->
            callback null, {}
        .catch (err) ->
            callback err

    writeBulk = (bulk, callback) ->
        opts = mixin _opts, body:bulk
        client.bulk(opts).then (res) ->
            if res?.errors
                # { index: { _index: 'blah', _type: 'ttninjs', _id: 'sdltb459b78', status: 400,
                #   error: { type: 'mapper_parsing_exception',
                #            reason: 'Field name [sdl.archivedBy] cannot contain \'.\''
                #            } } }
                oper = OPERS.find (oper) -> res.items[0]?[oper]
                reason = res.items[0]?[oper]?.error?.reason
                if reason
                    callback new Error(reason)
                else
                    callback res
            else
                callback null, res
        .catch (err) ->
            callback err

    bulkExec = (bulk, callback) ->
        # we try if any items are non-standard in which case
        # we must separate the bulk in different buckets
        # otherwise we just keep it intact
        if isNonStandard(bulk)
            a = []; m = []; b = []
            for item in bulk
                if item.alias
                    a.push item
                else if item.mapping
                    m.push item
                else
                    b.push item
            writeAlias(a, callback) if a.length
            writeMapping(m, callback) if m.length
            writeBulk(b, callback) if b.length
        else
            writeBulk bulk, callback

    count = 0

    stream = instream
    .pipe byline.createStream() # ensure we get whole lines
    .pipe fromJson()
    .pipe toDoc()
    .pipe through2.obj (doc, enc, callback) ->
        count++
        this.push doc
        callback()
    .pipe transform(operdelete, trans, _opts.index, _opts.type)
    .pipe new WritableBulk (bulk, callback) ->
        stream.emit 'progress', {count}
        bulkExec(bulk, callback)

    stream
