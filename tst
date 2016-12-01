#!/usr/bin/env coffee

argv = process.argv.slice(2)

require('./src/cmd')(process.stdin,process.stdout,process.stderr)(argv)
