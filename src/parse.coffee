url = require 'url'

module.exports = (u) ->

    p = url.parse(u)

    s = []
    s.push p.protocol
    s.push '//'
    if p.auth
        [user, pass] = p.auth.split ':'
        s.push encodeURIComponent(user)
        if pass
            s.push ':'
            s.push encodeURIComponent(pass)
        s.push '@'
    s.push p.hostname
    if p.port
        s.push ':'
        s.push p.port

    server = s.join('')

    [_, index, type] = (p.pathname ? '').split '/'

    query = p.query

    {
        server
        index: index ? ''
        type:  type ? ''
        query: query ? ''
    }
