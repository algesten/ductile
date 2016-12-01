WritableBulk = require './writable-bulk'
through2 = require 'through2'
byline   = require 'byline'
mixin    = require './mixin'

isTwoRow = (t) ->
    if typeof t == 'string'
        t in ['index', 'update', 'create']
    else
        t and (t.index or t.update or t.create)

OPERS = require './opers'

# test if bulk contains any non-standard bulk operations (alias, mapping or settings)
isNonStandard = (bulk) ->
    return true for b in bulk when b.alias or b.mapping or b.settings or b.template
    false

# value passed down the pipe to clean the state
CLEAN_PIPE = {clean:true}

fromJson = (emit) ->
    saved = null     # index are saved with next
    find123 = false  # 123 is {
    through2.obj (line, enc, callback) ->
        if find123
            if line[0] isnt 123
                return callback()
            else
                find123 = false
        json = try
            JSON.parse(line)
        catch ex
            if saved
                {message} = ex
                emit 'info', "Skipping record, JSON parse failed (#{message})
                on line after:\n#{JSON.stringify(saved)}"
                saved = null
                find123 = true # skip data until we find the next { at a start of a line
                null # null to json
            else
                throw ex
        if json == null
            # null is skipped, may be from catching an exception above
            # we must clean the pipe
            this.push CLEAN_PIPE
        else if saved != null
            this.push saved
            this.push json
            saved = null
        else if isTwoRow(json)
            saved = json
        else if json
            this.push json
        callback()

toDoc = ->
    d = (oper, source) ->
        opername = OPERS.find (o) -> oper[o]
        head = oper[opername]
        mixin head, _oper:opername, _source:source
    saved = null
    through2.obj (row, enc, callback) ->
        if row == CLEAN_PIPE
            saved = null
        else if saved
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
            else if t._oper == 'settings'
                oper.settings =
                    {_index:(index ? t._index), _settings:t._settings}
            else if t._oper == 'template'
                # name is not overridable by the url
                oper.template =
                    {_name:t._name, _template:t._template}
            else
                oper[t._oper] = {_id:t._id, _index:(index ? t._index), _type:(type ? t._type)}
            this.push oper
            if isTwoRow(t._oper)
                this.push t._source
        callback()

module.exports = (client, _opts, operdelete, trans, instream) ->

    writeAlias    = require('./write-alias')    client
    writeMapping  = require('./write-mapping')  client
    writeSettings = require('./write-settings') client
    writeTemplate = require('./write-template') client
    writeBulk     = require('./write-bulk')     client, _opts

    bulkExec = (bulk, callback) ->
        # we try if any items are non-standard in which case
        # we must separate the bulk in different buckets
        # otherwise we just keep it intact
        if isNonStandard(bulk)
            a = []; m = []; s = []; t = []; b = []
            for item in bulk
                if item.alias
                    a.push item
                else if item.mapping
                    m.push item
                else if item.settings
                    s.push item
                else if item.template
                    t.push item
                else
                    b.push item
            goterr = null
            anyerr = (err) -> goterr = err
            Promise.resolve().then ->
                writeTemplate(t, anyerr) if t.length
            .then ->
                writeSettings(s, anyerr) if s.length
            .then ->
                writeMapping(m, anyerr) if m.length
            .then ->
                writeBulk(b, anyerr) if b.length
            .then ->
                writeAlias(a, anyerr) if a.length
            .then ->
                if goterr then callback(goterr) else callback(null, {})
        else
            writeBulk bulk, callback

    count = 0

    fromJsonS = fromJson (as...) -> stream.emit as...

    stream = instream
    .pipe byline.createStream() # ensure we get whole lines
    .pipe fromJsonS
    .pipe toDoc()
    .pipe through2.obj (doc, enc, callback) ->
        count++
        this.push doc
        callback()
    .pipe transform(operdelete, trans, _opts.index, _opts.type)
    .pipe through2.obj (doc, enc, callback) ->
        this.push doc
        callback()
    .pipe new WritableBulk (bulk, callback) ->
        stream.emit 'progress', {count}
        bulkExec(bulk, callback)

    stream
