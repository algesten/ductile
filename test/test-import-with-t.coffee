streams = require './streams'

describe 'import', ->

    es = stdin = stdout = stderr = cmd = null

    beforeEach ->
        decache './trans.js'
        {es} = require('./mock-all')()
        stdin  = streams.bulk()
        stdout = streams.output()
        stderr = streams.output()
        cmd = require('../src/cmd')(stdin, stdout, stderr)

    afterEach ->
        mock.stopAll()

    describe 'with -t ./trans.js', ->

        it 'import a transformed bulk into es', ->
            cmd ['import', '-t', './test/trans.js', 'http://localhost:9200']
            streams.promise(stdin).then ->
                assert.deepEqual es().bulk.args[0][0], body:[
                    {
                        create:
                            _id: 'panda id'
                            _index: 'panda index'
                            _type: 'panda type'
                    }
                    {
                        uid: '0ea74996-f3f9-5a88-ba19-f5ea93afa833'
                        name: 'Dr. Leah F. Parker'
                        address: '362 Rurel Way'
                        panda: 'TRUE PANDA'
                    }
                ]
