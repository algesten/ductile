global.chai   = require 'chai'

sinon  = require 'sinon'
chai.use require 'sinon-chai'

global.stub    = sinon.stub
global.spy     = sinon.spy
global.match   = sinon.match
global.assert  = chai.assert
global.expect  = chai.expect
global.mock    = require 'mock-require'
global.decache = require 'decache'

process.env.__TESTING = '1'
