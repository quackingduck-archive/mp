mp = require 'message-ports'

# entry point
@run = (args) ->
  type = args.shift()
  type = typeAliases[type] if typeAliases[type]?
  validateType type
  port = args.shift()
  validatePort port
  port = parseInt port
  if args.length is 0
    interactiveMode type, port
  else
    printUsageAndExitWithError()

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

for name, longName of { pull: 'pull', sub: 'subscribe' }

  im[name] = (portNumber, messagePort) ->
    im.info "started #{longName} socket on port #{portNumber}"
    messagePort (msg) ->
      im.info "message received:"
      im.received msg

for name, longName of { push: 'push', pub: 'publish' }

  im[name] = (portNumber, messagePort, getLine) ->
    im.info "started #{longName} socket on port #{portNumber}"
    getAndSendMsg = ->
      getLine (line) ->
        messagePort line
        im.info "message sent"
        getAndSendMsg()

    getAndSendMsg()

im.info      = (msg) -> console.log '- ' + msg
im.received  = (msg) -> console.log '> ' + msg

# --

typeAliases =
  request: 'req', reply: 'rep', publish: 'pub', subscribe: 'sub'

typeExp = /// ^ rep | req | push | pull | pub | sub $ ///
portExp = /// ^ \d+ $ ///

# todo
validateType = (type) ->
  unless typeExp.test type
    console.log "#{type} isn't a valid message port type"
    printUsageAndExitWithError()

validatePort = (port) ->
  # todo: validate port in range
  unless portExp.test port
    console.log "#{port} isn't a valid port number"
    printUsageAndExitWithError()

printUsageAndExitWithError = ->
  console.log usage
  process.exit 1

# todo: expand
usage = """
usage: mp reply 2000
"""
