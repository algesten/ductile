elasticsearch = require 'elasticsearch'
ElasticLogger = require './elastic-logger'

module.exports = (target) ->

    opts =
        host           : target.server
        log            : ElasticLogger
        requestTimeout : 60000
        deadTimeout    : 90000

    new elasticsearch.Client(opts)
