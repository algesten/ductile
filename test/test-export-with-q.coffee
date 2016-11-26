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

    describe 'with -q ./query.json', ->

        describe 'with bad file', ->

            it 'reports error', ->
                cmd ['export', '-q', './test/xxx.json', 'http://localhost:9200/myindex']
                assert.deepEqual streams.string(stderr)
                , 'File not found: /Users/martin/dev/ductile/test/xxx.json\n'

        describe 'with good file', ->

            it 'exports transformed bulk', ->
                cmd ['export', '-q', './test/query.json', 'http://localhost:9200/myindex']
                streams.promise(stdout).then ->
                    assert.deepEqual es().search.args[0][0],
                        body:query:fantastic_panda:true
                        index: 'myindex'
                        scroll: '60s'
                        size: 200
