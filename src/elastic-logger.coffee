log = require 'bog'

module.exports = class ElasticLogger
    constructor: (@config) ->
    error:   log.error
    warning: log.warn
    info:    log.info
    debug:   log.debug
    trace: (method, url, body, response, status) ->
