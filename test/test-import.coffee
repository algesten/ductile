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

    describe 'without index/type in the url', ->
        it 'import bulk to es without overrides', ->
            cmd ['import', 'http://localhost:9200']
            streams.promise(stdin).then ->
                assert.deepEqual es().bulk.args[0][0],
                {body:require('./test.bulk.coffee')()}
            .then ->
                assert.deepEqual streams.string(stderr), 'Imported 2\n'

    describe 'with index in the url', ->
        it 'import bulk to es with override index', ->
            cmd ['import', 'http://localhost:9200/panda']
            streams.promise(stdin).then ->
                assert.deepEqual es().bulk.args[0][0],
                {index:'panda', body:require('./test.bulk.coffee')('panda')}

    describe 'with index/type in the url', ->
        it 'import bulk to es with override index/type', ->
            cmd ['import', 'http://localhost:9200/panda/cub']
            streams.promise(stdin).then ->
                assert.deepEqual es().bulk.args[0][0],
                {index:'panda', type:'cub', body:require('./test.bulk.coffee')('panda', 'cub')}
