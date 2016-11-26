streams = require './streams'

describe 'import', ->

    es = stdin = stdout = stderr = cmd = null

    beforeEach ->
        {es} = require('./mock-all')()
        stdin  = streams.u0085()
        stdout = streams.output()
        stderr = streams.output()
        cmd = require('../src/cmd')(stdin, stdout, stderr)

    afterEach ->
        mock.stopAll()

    describe 'of a bad u0085 char', ->
        it 'import bulk to es without overrides', ->
            cmd ['import', 'http://localhost:9200']
            streams.promise(stdin).then ->
                assert.deepEqual es().bulk.args[0][0],
                {
                    body:[
                        {index:{_id:'id-second', _index:'myindex', _type:'mytype'}}
                        {body_text:'Second.Test 123 '}
                    ]
                }
                assert.deepEqual stderr.getContentsAsString?('utf8'), COMPARE.join('')

COMPARE = [
    "Skipping record, JSON parse failed (Unexpected end of JSON input) on line after:\n"
    "{\"index\":{\"_index\":\"myindex\",\"_type\":\"mytype\",\"_id\":\"id-first\"}}\n"
    "Imported 1\n"
]
