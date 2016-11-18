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

    describe 'with -d', ->

        it 'exports to delete bulk', ->
            cmd ['export', '-d', 'http://localhost:9200/myindex']
            streams.promise(stdout)
            .then (bulk) ->
                cmp = es.docs().map (d) ->
                    delete:{_index:'myindex', _type:'mytype', _id:d.uid}
                .map (r) -> JSON.stringify(r)
                .join('\n') + '\n'
                assert.deepEqual bulk, cmp
            .then ->
                assert.deepEqual streams.string(stderr),
                'Exported 10/42\nExported 20/42\nExported 30/42\nExported 40/42\nExported 42/42\n'
