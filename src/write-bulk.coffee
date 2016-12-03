mixin    = require './mixin'

OPERS = require './opers'

module.exports = (client, _opts) -> (bulk, emit, callback) ->
    opts = mixin _opts, body:bulk
    client.bulk(opts).then (res) ->
        if res?.errors
            # { index: { _index: 'blah', _type: 'ttninjs', _id: 'sdltb459b78', status: 400,
            #   error: { type: 'mapper_parsing_exception',
            #            reason: 'Field name [sdl.archivedBy] cannot contain \'.\''
            #            } } }
            (res.items ? []).forEach (i) ->
                oper = OPERS.find (oper) -> i?[oper]
                rec = i[oper]
                if rec?.error
                    {reason} = rec.error
                    if rec._index and rec._type and rec._id
                        emit 'info', "Skipping (#{rec._index}/#{rec._type}/#{rec._id}): #{reason}"
                    else
                        emit 'info', "Skipping record: #{reason}"
            callback null, res
        else
            callback null, res
    .catch (err) ->
        callback err
