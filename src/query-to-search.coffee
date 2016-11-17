querystring = require 'querystring'
log = require 'bog'

asInt = (s) ->
    return undefined unless s
    try
        n = parseInt(s, 10)
        throw Error('nan') if isNaN(n)
        n
    catch ex
        log.warn "Failed to interpret as int: #{s}"
        undefined

module.exports = (str) ->

    p = querystring.parse str

    {
        q: p.q ? ''
        from: asInt(p.from) ? 0
        size: asInt(p.size) ? 10
        sort: p.sort ? ''
    }
