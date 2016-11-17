elasticsearch = require 'elasticsearch'
ElasticLogger = require './elastic-logger'
parse         = require './parse'
mixin         = require './mixin'
reader        = require './reader'
writer        = require './writer'
queryToSearch = require './query-to-search'

module.exports = (url, apiVersion) ->

    target = parse(url)

    opts =
        host           : target.server
        log            : ElasticLogger
        requestTimeout : 60000
        deadTimeout    : 90000

    opts.apiVersion = apiVersion if apiVersion

    client = new elasticsearch.Client(opts)

    # holds {q}
    search = queryToSearch(target.query)

    reader: (lsearch, operdelete, trans) ->

        # merged search in order of precedence
        msearch = mixin search, lsearch, {index:target.index, type:target.type}

        reader(client, msearch, operdelete, trans)

    writer: (operdelete, trans, instream) ->

        writer(client, {index:target.index, type:target.type}, operdelete, trans, instream)
