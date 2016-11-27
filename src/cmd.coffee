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

    errmsg = (err) -> err.body?.error?.reason ? err.message ? err

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
        command: 'import [options] <url>'
        alias:   'i'
        desc:    'Bulk import items (anything exported)',
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
            .on 'info', outerr
            .on 'error', (err) ->
                outerr 'IMPORT ERROR:', errmsg(err)
                unless process.env.__TESTING == '1'
                    process.exit -1


    .command
        command: 'export [options] <url>'
        alias:   'e'
        desc:    'Bulk export documents',
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
                outerr 'EXPORT ERROR:', errmsg(err)
            .pipe(stdout)
            .on 'error', (err) ->
                if err.code == 'EPIPE'
                    # broken pipe
                    unless process.env.__TESTING == '1'
                        process.exit -1
                else
                    outerr 'EXPORT ERROR:', err

    .command
        command: 'alias <url>'
        alias:   'a'
        desc:    'Bulk export aliases',
        builder: (yargs) ->
            yargs
            .strict()
            .usage('\nUsage: ductile alias <url>')
            .demand(1)
        handler: (argv) ->
            ductile(argv.url)
            .alias()
            .on 'error', (err) ->
                outerr 'EXPORT ERROR:', errmsg(err)
            .pipe(stdout)
            .on 'error', (err) ->
                if err.code == 'EPIPE'
                    # broken pipe
                    unless process.env.__TESTING == '1'
                        process.exit -1
                else
                    outerr 'EXPORT ERROR:', err


    .command
        command: 'mappings <url>'
        alias:   'm'
        desc:    'Bulk export mappings',
        builder: (yargs) ->
            yargs
            .strict()
            .usage('\nUsage: ductile mappings <url>')
            .demand(1)
        handler: (argv) ->
            ductile(argv.url)
            .mappings()
            .on 'error', (err) ->
                outerr 'EXPORT ERROR:', errmsg(err)
            .pipe(stdout)
            .on 'error', (err) ->
                if err.code == 'EPIPE'
                    # broken pipe
                    unless process.env.__TESTING == '1'
                        process.exit -1
                else
                    outerr 'EXPORT ERROR:', err


    .command
        command: 'settings <url>'
        alias:   'm'
        desc:    'Bulk export settings',
        builder: (yargs) ->
            yargs
            .strict()
            .usage('\nUsage: ductile settings <url>')
            .demand(1)
        handler: (argv) ->
            ductile(argv.url)
            .settings()
            .on 'error', (err) ->
                outerr 'EXPORT ERROR:', errmsg(err)
            .pipe(stdout)
            .on 'error', (err) ->
                if err.code == 'EPIPE'
                    # broken pipe
                    unless process.env.__TESTING == '1'
                        process.exit -1
                else
                    outerr 'EXPORT ERROR:', err

    .command
        command: 'template <url>'
        alias:   't'
        desc:    'Bulk export template',
        builder: (yargs) ->
            yargs
            .strict()
            .usage('\nUsage: ductile template <url>')
            .demand(1)
        handler: (argv) ->
            ductile(argv.url)
            .template()
            .on 'error', (err) ->
                outerr 'EXPORT ERROR:', errmsg(err)
            .pipe(stdout)
            .on 'error', (err) ->
                if err.code == 'EPIPE'
                    # broken pipe
                    unless process.env.__TESTING == '1'
                        process.exit -1
                else
                    outerr 'EXPORT ERROR:', err



    .example 'ductile export http://localhost:9200/myindex'
    .example 'ductile export http://localhost:9200/myindex/mytype > dump.bulk'
    .example 'ductile import http://localhost:9200/myindex/mytype < dump.bulk'
    .help()
    .showHelpOnFail()

    argv = yargs.argv

    unless argv._.length
        yargs.showHelp()
