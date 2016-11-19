

module.exports = (client) -> (bulk, callback) ->
    bulk.reduce (p, c) ->
        p.then ->
            t = c.mapping
            putmapping = ->
                client.indices.putMapping {index:t._index, type:t._type, body:t._mapping}
            putmapping().catch (err) ->
                if err.status == 404
                    client.indices.create {index:t._index}
                    .then putmapping
                else
                    throw err
    , Promise.resolve()
    .then ->
        callback null, {}
    .catch (err) ->
        callback err
