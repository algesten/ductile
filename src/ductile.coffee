parse         = require './parse'
mixin         = require './mixin'
reader        = require './reader'
alias         = require './alias'
writer        = require './writer'
queryToSearch = require './query-to-search'

module.exports = (url) ->

    target = parse(url)

    client = require('./es') target

    # holds {q}
    search = queryToSearch(target.query)

    reader: (lsearch, operdelete, trans) ->

        # merged search in order of precedence
        msearch = mixin search, lsearch, {index:target.index, type:target.type}

        reader(client, msearch, operdelete, trans)

    alias: ->

        alias(client, {index:target.index})

    writer: (operdelete, trans, instream) ->

        writer(client, {index:target.index, type:target.type}, operdelete, trans, instream)
