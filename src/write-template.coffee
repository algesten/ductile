

module.exports = (client) -> (bulk, callback) ->
    bulk.reduce (p, c) ->
        p.then ->
            t = c.template
            client.indices.putTemplate {name:t._name, body:t._template}
    , Promise.resolve()
    .then ->
        callback null, {}
    .catch (err) ->
        callback err
