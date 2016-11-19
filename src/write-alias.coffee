
module.exports = (client) -> (bulk, callback) ->
    bulk.reduce (p, c) ->
        p.then ->
            t = c.alias
            putalias = -> client.indices.putAlias {name:t._name, index:t._index}
            putalias().catch (err) ->
                if err.status == 404
                    client.indices.create {index:t._index}
                    .then putalias
                else
                    throw err

    , Promise.resolve()
    .then ->
        callback null, {}
    .catch (err) ->
        callback err
