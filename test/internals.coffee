assert = require 'assert'
int = require('../src/mp')._test

suite 'Interals - parseArgs'

test 'help', ->
  args = int.parseArgs ['help']
  assert.ok args.help

  args = int.parseArgs ['-h']
  assert.ok args.help

  args = int.parseArgs ['--help']
  assert.ok args.help

test 'type', ->
  assert.equal int.parseArgs(['pub']).type, 'pub'

test 'port', ->
  assert.equal int.parseArgs(['pub', '4000']).port, '4000'

# ---

suite 'Interals - parsePort'

test 'ints get parsed', ->
  assert.equal int.parsePort('2000'), 2000

test 'everything else passed through', ->
  assert.equal int.parsePort('foo'), "foo"

# ---

suite 'Interals - parseType'

test 'long names convert to short', ->
  assert.equal int.parseType('publish'), 'pub'
  assert.equal int.parseType('subscribe'), 'sub'
  assert.equal int.parseType('request'), 'req'
  assert.equal int.parseType('reply'), 'rep'

test 'everything else passes through', ->
  assert.equal int.parseType('foozle'), 'foozle'

# ---

suite "Interals - validateType"

test 'valid port types', ->
  assert int.validateType 'pub'
  assert int.validateType 'sub'
  assert int.validateType 'req'
  assert int.validateType 'rep'
  assert int.validateType 'push'
  assert int.validateType 'pull'

test 'everthing else invalid', ->
  assert not int.validateType 'publish'
  assert not int.validateType 'foo'


# ---

suite "Interals - validatePort"

test 'valid port ids', ->
  assert int.validatePort 9000
  assert int.validatePort '/tmp/foo'
  assert int.validatePort 'tcp://192.168.1.1:3000'

test 'everthing else invalid', ->
  assert not int.validatePort 'foo'



