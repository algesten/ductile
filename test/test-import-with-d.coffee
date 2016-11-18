streams = require './streams'

describe 'import', ->

    es = stdin = stdout = stderr = cmd = null

    beforeEach ->
        {es} = require('./mock-all')()
        stdin  = streams.bulk()
        stdout = streams.output()
        stderr = streams.output()
        cmd = require('../src/cmd')(stdin, stdout, stderr)

    afterEach ->
        mock.stopAll()

    describe 'with -d', ->
        it 'turns import to delete', ->
            cmd ['import', '-d', 'http://localhost:9200']
            streams.promise(stdin).then ->
                assert.deepEqual es().bulk.args[0][0], body:[
                    {
                         delete:
                             _id: '0ea74996-f3f9-5a88-ba19-f5ea93afa833'
                             _index: 'myindex'
                             _type: 'mytype'
                    }
                    {
                        delete:
                            _id: '7303e089-1b8f-5556-b427-8189d17d993a'
                            _index: 'myindex'
                            _type: 'mytype'
                    }
                ]
