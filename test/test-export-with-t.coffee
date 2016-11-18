streams = require './streams'

describe 'export', ->

    es = stdin = stdout = stderr = cmd = null

    beforeEach ->
        decache './trans.js'
        {es} = require('./mock-all')()
        stdin  = streams.empty()
        stdout = streams.output()
        stderr = streams.output()
        cmd = require('../src/cmd')(stdin, stdout, stderr)

    afterEach ->
        mock.stopAll()

    describe 'with -t ./trans.js', ->

        describe 'with bad file', ->

            it 'reports error', ->
                cmd ['export', '-t', './test/xxx.json', 'http://localhost:9200/myindex']
                assert.deepEqual streams.string(stderr)
                , 'File not found: /Users/martin/dev/ductile/test/xxx.json\n'

        describe 'with good file', ->

            it 'exports transformed bulk', ->
                cmd ['export', '-t', './test/trans.js', 'http://localhost:9200/myindex']
                streams.promise(stdout)
                .then (bulk) ->
                    cmp = ([
                        {"index":{"_index":"panda index","_type":"panda type","_id":"panda id"}},
                        Object.assign es.docs()[0], {panda:"TRUE PANDA"}
                    ]).map (r) -> JSON.stringify(r)
                    .join('\n') + '\n'
                    assert.deepEqual bulk, cmp
                .then ->
                    assert.deepEqual streams.string(stderr),
                    'Exported 10/42\nExported 20/42\nExported 30/42\n' +
                    'Exported 40/42\nExported 42/42\n'
