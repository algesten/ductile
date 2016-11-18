ductile = require './ductile'
{join, sep} = require 'path'
log  = require 'bog'

module.exports = (stdin, stdout, stderr) -> (_argv)  ->

    outerr = (s1, s2, s3) ->
        if arguments.length == 3
            stderr.write "#{s1} #{s2} #{s3}\n"
        else if arguments.length == 2
            stderr.write "#{s1} #{s2}\n"
        else if arguments.length == 1
            stderr.write "#{s1}\n"
        else
            stderr.write "\n"

    log.redirect outerr, outerr
    log.level 'warn'

    readfile = (f) ->
        path = if f[0] == sep then f else join(process.cwd(), f)
        try
            require(path)
        catch ex
            if ex.code == 'MODULE_NOT_FOUND'
                outerr "File not found: #{path}"
                unless process.env.__TESTING == '1'
                    process.exit -1
            else
                throw ex

    yargs = require('yargs')(_argv).usage('\nUsage: ductile <command> [options] <url>')

    .strict()
    .wrap(null)

    .command
        command: 'export [options] <url>'
        aliase:  'e'
        desc:    'Bulk export items',
        builder: (yargs) ->
            yargs
            .strict()
            .usage('\nUsage: ductile export [options] <url>')
            .option 'd',
                alias:    'delete'
                default:  false
                describe: 'output delete operations'
                type:     'boolean'
            .option 'q',
                alias:    'query'
                describe: 'file with json query'
                type:     'string'
            .option 't',
                alias:    'transform'
                describe: 'file with transform function'
                type:     'string'
            .demand(1)
        handler: (argv) ->
            odelete = argv["delete"]
            body = readfile(argv.q) if argv.q
            trans = (if argv.t then readfile(argv.t)) ? (v) -> v
            lsearch = {body}
            ductile(argv.url)
            .reader(lsearch, odelete, trans)
            .on 'progress', (p) ->
                outerr "Exported #{p.from}/#{p.total}"
            .on 'error', (err) ->
                outerr 'EXPORT ERROR:', err.message
                stderr.end()
            .pipe(stdout)
            .on 'error', (err) ->
                if err.code == 'EPIPE'
                    # broken pipe
                    process.exit -1
                else
                    outerr 'EXPORT ERROR:', err

    .command
        command: 'import [options] <url>'
        aliase:  'i'
        desc:    'Bulk import items',
        builder: (yargs) ->
            yargs
            .strict()
            .usage '\nUsage: ductile import [options] <url>'
            .option 'd',
                alias:    'delete'
                default:  false
                describe: 'change incoming index operations to delete'
                type:     'boolean'
            .option 't',
                alias:    'transform'
                describe: 'file with transform function'
                type:     'string'
            .demand(1)
        handler: (argv) ->
            odelete = argv["delete"]
            trans = if argv.t then readfile(argv.t) else (v) -> v
            ductile(argv.url)
            .writer(odelete, trans, stdin)
            .on 'progress', (p) ->
                outerr "Imported #{p.count}"
            .on 'error', (err) ->
                outerr 'IMPORT ERROR:', err.message
                process.exit -1


    .example 'ductile export http://localhost:9200/myindex'
    .example 'ductile export http://localhost:9200/myindex/mytype > dump.bulk'
    .example 'ductile import http://localhost:9200/myindex/mytype < dump.bulk'
    .help()
    .showHelpOnFail()

    argv = yargs.argv

    unless argv._.length
        yargs.showHelp()
