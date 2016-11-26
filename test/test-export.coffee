streams = require './streams'

describe 'export', ->

    es = stdin = stdout = stderr = cmd = null

    beforeEach ->
        {es} = require('./mock-all')()
        stdin  = streams.empty()
        stdout = streams.output()
        stderr = streams.output()
        cmd = require('../src/cmd')(stdin, stdout, stderr)

    afterEach ->
        mock.stopAll()

    describe 'with no options', ->
        it 'exports to bulk', ->
            cmd ['export', 'http://localhost:9200/myindex']
            streams.promise(stdout)
            .then (bulk) ->
                cmp = ([].concat.apply [], es.docs().map (d) ->
                    [{index:{_index:'myindex', _type:'mytype', _id:d.uid}}, d]
                    ).map (r) -> JSON.stringify(r)
                    .join('\n') + '\n'
                assert.deepEqual bulk, cmp
            .then ->
                assert.deepEqual streams.string(stderr),
                'Exported 10/42\nExported 20/42\nExported 30/42\nExported 40/42\nExported 42/42\n'

    describe 'without index/type in the url', ->
        it 'exports to bulk without index/type', ->
            cmd ['export', 'http://localhost:9200']
            streams.promise(stdout).then ->
                assert.deepEqual es().search.args[0][0],
                    body:query:match_all:{}
                    scroll: '60s'
                    size: 200

    describe 'with index in the url', ->
        it 'exports to bulk with index', ->
            cmd ['export', 'http://localhost:9200/panda']
            streams.promise(stdout).then ->
                assert.deepEqual es().search.args[0][0],
                    body:query:match_all:{}
                    index: 'panda'
                    scroll: '60s'
                    size: 200

    describe 'with index/type in the url', ->
        it 'exports to bulk with index/type', ->
            cmd ['export', 'http://localhost:9200/panda/cub']
            streams.promise(stdout).then ->
                assert.deepEqual es().search.args[0][0],
                    body:query:match_all:{}
                    index: 'panda'
                    type: 'cub'
                    scroll: '60s'
                    size: 200

    describe 'with a q= in the url', ->
        it 'includes q field in the body', ->
            cmd ['export', 'http://localhost:9200/panda/cub?q=published:true']
            streams.promise(stdout).then ->
                assert.deepEqual es().search.args[0][0],
                    q: 'published:true'
                    index: 'panda'
                    type: 'cub'
                    scroll: '60s'
                    size: 200
