###*
# Expose a writeable stream and execute it as a set of bulk requests.
###

###*
# @param bulkExec closure invoked with the bulk cmds as an array and a callback
# @param highWaterMark number of bulk commands executed at once. 128 by default.
###

WritableBulk = (bulkExec, highWaterMark) ->
  if !(this instanceof WritableBulk)
    return new WritableBulk(bulkExec, highWaterMark)
  Writable.call this, objectMode: true
  @bulkExec = bulkExec
  @highWaterMark = highWaterMark or 128
  @bulk = []
  @bulkCount = 0
  @expectingPayload = false
  # when end is called we still need to flush but we must not overwrite end ourself.
  # now we need to tell everyone to listen to the close event to know when we are done.
  # Not great. See: https://github.com/joyent/node/issues/5315#issuecomment-16670354
  @on 'finish', (->
    @_flushBulk (->
      @emit 'close'
      return
    ).bind(this)
    return
  ).bind(this)
  return

'use strict'
Writable = require('stream').Writable
module.exports = WritableBulk
WritableBulk.prototype = Object.create(Writable.prototype, constructor: value: WritableBulk)

###*
# @param chunk a piece of a bulk request as json.
###

WritableBulk::_write = (chunk, enc, next) ->
  if @expectingPayload
    @bulkCount++
    @expectingPayload = false
  else
    willExpectPayload = [
      'index'
      'create'
      'update'
    ]
    i = 0
    while i < willExpectPayload.length
      if chunk.hasOwnProperty(willExpectPayload[i])
        @expectingPayload = willExpectPayload[i]
        break
      i++
    if !@expectingPayload
      if !chunk.hasOwnProperty('delete') and !chunk.hasOwnProperty('alias') and !chunk.hasOwnProperty('mapping') and !chunk.hasOwnProperty('settings') and !chunk.hasOwnProperty('template')
        @emit 'error', new Error('Unexpected chunk, not an ' + 'index/create/update/delete/alias/mapping/settings/template command and ' + 'not a document to index either')
        return next()
      @bulkCount++
  @bulk.push chunk
  if @highWaterMark <= @bulkCount
    return @_flushBulk(next)
  next()
  return

WritableBulk::_flushBulk = (callback) ->
  if !@bulkCount
    return setImmediate(callback)
  self = this
  @bulkExec @bulk, (e, resp) ->
    if e
      self.emit 'error', e
    # if resp.errors and resp.items
    #   i = 0
    #   while i < resp.items.length
    #     bulkItemResp = resp.items[i]
    #     key = Object.keys(bulkItemResp)[0]
    #     if bulkItemResp[key].error
    #       self.emit 'error', new Error(bulkItemResp[key].error)
    #     i++
    self.bulk = []
    self.bulkCount = 0
    self.expectingPayload = false
    callback()
    return
  return

# ---
# generated by js2coffee 2.2.0
