Chance = require('chance')

chance = new Chance()

clone = (o) -> JSON.parse JSON.stringify o

doc = ->
    uid: chance.guid()
    name: chance.name
        middle_initial: true,
        prefix: true
    description: chance.sentence()
    address: chance.address()

N = 42

docs = (new Array(N)).fill(0).map -> doc()
hits = docs.map (d) ->
    _id: d.uid
    _type: 'mytype'
    _index: 'myindex'
    _source: d

c = 0

reset = -> c = 0

iter = ->
    c += 10
    clone hits.slice(c - 10, c)

search = spy (opts, cb) -> reset(); setImmediate ->
    cb null, {_scroll_id:'123', hits:{total:N, hits:iter()}}
scroll = spy (opts, cb) -> setImmediate ->
    cb null, {_scroll_id:'123', hits:{total:N, hits:iter()}}
bulk = spy (opts, cb) -> Promise.resolve {}

fn = -> {search, scroll, bulk}
fn.docs = -> clone docs

module.exports = fn
