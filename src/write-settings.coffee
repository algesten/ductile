
module.exports = (client) -> (bulk, callback) ->
    bulk.reduce (p, c) ->
        p.then ->
            t = c.settings
            {number_of_replicas, number_of_shards} = t._settings?.index ? {}
            if t._settings.index
                delete t._settings.index.number_of_replicas
                delete t._settings.index.number_of_shards
            putsettings = ->
                attempt = ->
                    (if t._settings.analysis
                        client.indices.close index:t._index
                    else
                        Promise.resolve()
                    ).then ->
                        client.indices.putSettings {index:t._index, body:t._settings}
                    .then (res) ->
                        (if t._settings.analysis
                            client.indices.open index:t._index
                        else
                            Promise.resolve()
                        ).then -> res
                    .catch (err) ->
                        if err.body?.error?.type == 'index_primary_shard_not_allocated_exception'
                            # this happens when the index is newly created
                            attempt()
                        else
                            throw err
                attempt()
            putsettings().catch (err) ->
                if err.status == 404
                    opts = {index:t._index, body:{}}
                    if number_of_replicas?
                        opts.body.number_of_replicas = number_of_replicas
                    if number_of_shards?
                        opts.body.number_of_shards = number_of_shards
                    client.indices.create opts
                    .then putsettings
                else
                    throw err
    , Promise.resolve()
    .then ->
        callback null, {}
    .catch (err) ->
        callback err
