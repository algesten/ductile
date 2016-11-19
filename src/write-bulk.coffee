mixin    = require './mixin'

module.exports = (client, _opts) -> (bulk, callback) ->
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
