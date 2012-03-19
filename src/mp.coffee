mp = require 'message-ports'

# entry point
@run = (rawArgs) ->
  printUsageAndExit(1) if rawArgs.length is 0
  args = parseArgs rawArgs

  printUsageAndExit(0) if args.help is yes

  type = parseType args.type
  unless validateType type
    console.log "#{type} isn't a valid port type"
    printUsageAndExit(1)

  port = parsePort args.port
  unless validatePort port
    console.log "#{port} isn't a valid port id"
    printUsageAndExit(1)

  interactiveMode type, port

# ---

# ## Interactive Modes

interactiveMode = (type, port) ->
  process.stdin.setEncoding 'utf8'
  input = require('readline').createInterface process.stdin, process.stdout
  input.setPrompt '< '

  mp.messageFormat = 'utf8'
  messagePort = mp[type](port)

  input.on 'close', ->
    process.stdout.write '\n'
    process.stdin.destroy()
    messagePort.close()

  getLine = (callback) ->
    input.once 'line', callback
    input.prompt()

  interactiveMode[type](port, messagePort, getLine)

# shortens namespace
im = interactiveMode

im.rep = (portNumber, messagePort, getLine) ->
  reply = messagePort
  im.info "started reply socket on port #{portNumber}"
  im.info "waiting for request"
  reply (requestMsg, send) ->
    im.info "request received:"
    im.received requestMsg
    getLine (line) ->
      send line
      im.info "reply sent"
      im.info "waiting for request"

im.req = (portNumber, messagePort, getLine) ->
  request = messagePort
  im.info "started request socket on port #{portNumber}"
  # starts the request/response cycle
  getMsgSendMsgWaitMsgRepeat = ->
    getLine (line) ->
      request line, (replyMsg) ->
        im.info "reply received:"
        im.received replyMsg
        getMsgSendMsgWaitMsgRepeat()

      im.info "request sent"
      im.info "waiting for reply"

  getMsgSendMsgWaitMsgRepeat()

# pull/subscribe and push/publish have the same interfaces at this level

['pull', 'sub'].forEach (name) ->

  im[name] = (portNumber, messagePort) ->
    im.info "started #{im.longName name} socket on port #{portNumber}"
    messagePort (msg) ->
      im.info "message received:"
      im.received msg

['push', 'pub'].forEach (name) ->

  im[name] = (portNumber, messagePort, getLine) ->
    im.info "started #{im.longName name} socket on port #{portNumber}"
    getAndSendMsg = ->
      getLine (line) ->
        messagePort line
        im.info "message sent"
        getAndSendMsg()

    getAndSendMsg()

im.info      = (msg) -> console.log ansi.gray + '- ' + msg + ansi.reset
im.received  = (msg) -> console.log '> ' + msg

im.longName = (portType) ->
  {
    req: 'request', rep: 'reply'
    pub: 'publish', sub: 'subscribe'
    push: 'push', pull: 'pull'
  }[portType]

ansi =
  gray:  '\x1b[0;37m'
  reset: '\x1b[m'

# --

parseArgs = (rawArgs) ->
  if rawArgs[0].match ///^ ( help | --help | -h ) $///
    return { help: yes }

  { type: rawArgs[0], port: rawArgs[1] }

parseType = (typeArg) ->
  # convert long names to short ones
  { request: 'req', reply: 'rep', publish: 'pub', subscribe: 'sub' }[typeArg] or typeArg

parsePort = (portArg) ->
  # coerce numeric string into number
  if portArg.match /// ^ \d+ $ /// then parseInt portArg else portArg

validateType = (type) ->
  type.match /// ^ ( rep | req | push | pull | pub | sub ) $ ///


validatePort = (port) ->
  return yes if typeof port is 'number'
  return yes if typeof port is 'string' and port[0] is '/'
  return yes if typeof port is 'string' and port.match /// ^ \w+ : // ///

# ---

printUsageAndExit = (status) ->
  console.log usage
  process.exit status

usage = """
Usage:
  mp <port-type> <port-id>

Required:
  <port-type>
    Can be one of: req, rep, pub, sub, push, pull

  <port-id>
    Must be a valid message port id

Each port type can be thought of as one end of a client/server connection.

Request (req) ports must connect to Reply (rep) ports
Subscribe (sub) ports must connect to Publish (pub) ports
Push ports must connect to Pull ports

Examples:
  mp req 2000
  mp rep 2000
  mp pub /tmp/pub
  mp sub /tmp/pub
"""

# ---

@_test = { parseArgs, parsePort, parseType, validatePort, validateType }
