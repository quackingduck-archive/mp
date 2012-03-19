(function() {
  var ansi, im, interactiveMode, longName, mp, name, parseArgs, parsePort, parseType, printUsageAndExit, usage, validatePort, validateType, _ref, _ref2;

  mp = require('message-ports');

  this.run = function(rawArgs) {
    var args, port, type;
    if (rawArgs.length === 0) printUsageAndExit(1);
    args = parseArgs(rawArgs);
    if (args.help === true) printUsageAndExit(0);
    type = parseType(args.type);
    if (!validateType(type)) {
      console.log("" + type + " isn't a valid port type");
      printUsageAndExit(1);
    }
    port = parsePort(args.port);
    if (!validatePort(port)) {
      console.log("" + port + " isn't a valid port id");
      printUsageAndExit(1);
    }
    return interactiveMode(type, port);
  };

  interactiveMode = function(type, port) {
    var getLine, input, messagePort;
    process.stdin.setEncoding('utf8');
    input = require('readline').createInterface(process.stdin, process.stdout);
    input.setPrompt('< ');
    mp.messageFormat = 'utf8';
    messagePort = mp[type](port);
    input.on('close', function() {
      process.stdout.write('\n');
      process.stdin.destroy();
      return messagePort.close();
    });
    getLine = function(callback) {
      input.once('line', callback);
      return input.prompt();
    };
    return interactiveMode[type](port, messagePort, getLine);
  };

  im = interactiveMode;

  im.rep = function(portNumber, messagePort, getLine) {
    var reply;
    reply = messagePort;
    im.info("started reply socket on port " + portNumber);
    im.info("waiting for request");
    return reply(function(requestMsg, send) {
      im.info("request received:");
      im.received(requestMsg);
      return getLine(function(line) {
        send(line);
        im.info("reply sent");
        return im.info("waiting for request");
      });
    });
  };

  im.req = function(portNumber, messagePort, getLine) {
    var getMsgSendMsgWaitMsgRepeat, request;
    request = messagePort;
    im.info("started request socket on port " + portNumber);
    getMsgSendMsgWaitMsgRepeat = function() {
      return getLine(function(line) {
        request(line, function(replyMsg) {
          im.info("reply received:");
          im.received(replyMsg);
          return getMsgSendMsgWaitMsgRepeat();
        });
        im.info("request sent");
        return im.info("waiting for reply");
      });
    };
    return getMsgSendMsgWaitMsgRepeat();
  };

  _ref = {
    pull: 'pull',
    sub: 'subscribe'
  };
  for (name in _ref) {
    longName = _ref[name];
    im[name] = function(portNumber, messagePort) {
      im.info("started " + longName + " socket on port " + portNumber);
      return messagePort(function(msg) {
        im.info("message received:");
        return im.received(msg);
      });
    };
  }

  _ref2 = {
    push: 'push',
    pub: 'publish'
  };
  for (name in _ref2) {
    longName = _ref2[name];
    im[name] = function(portNumber, messagePort, getLine) {
      var getAndSendMsg;
      im.info("started " + longName + " socket on port " + portNumber);
      getAndSendMsg = function() {
        return getLine(function(line) {
          messagePort(line);
          im.info("message sent");
          return getAndSendMsg();
        });
      };
      return getAndSendMsg();
    };
  }

  im.info = function(msg) {
    return console.log(ansi.gray + '- ' + msg + ansi.reset);
  };

  im.received = function(msg) {
    return console.log('> ' + msg);
  };

  ansi = {
    gray: '\x1b[0;37m',
    reset: '\x1b[m'
  };

  parseArgs = function(rawArgs) {
    if (rawArgs[0].match(/^(help|--help|-h)$/)) {
      return {
        help: true
      };
    }
    return {
      type: rawArgs[0],
      port: rawArgs[1]
    };
  };

  parseType = function(typeArg) {
    return {
      request: 'req',
      reply: 'rep',
      publish: 'pub',
      subscribe: 'sub'
    }[typeArg] || typeArg;
  };

  parsePort = function(portArg) {
    if (portArg.match(/^\d+$/)) {
      return parseInt(portArg);
    } else {
      return portArg;
    }
  };

  validateType = function(type) {
    return type.match(/^(rep|req|push|pull|pub|sub)$/);
  };

  validatePort = function(port) {
    if (typeof port === 'number') return true;
    if (typeof port === 'string' && port[0] === '/') return true;
    if (typeof port === 'string' && port.match(/^\w+:\/\//)) return true;
  };

  printUsageAndExit = function(status) {
    console.log(usage);
    return process.exit(status);
  };

  usage = "Usage:\n  mp <port-type> <port-id>\n\nRequired:\n  <port-type>\n    Can be one of: req, rep, pub, sub, push, pull\n\n  <port-id>\n    Must be a valid message port id\n\nEach port type can be thought of as one end of a client/server connection.\n\nRequest (req) ports must connect to Reply (rep) ports\nSubscribe (sub) ports must connect to Publish (pub) ports\nPush ports must connect to Pull ports\n\nExamples:\n  mp req 2000\n  mp rep 2000\n  mp pub /tmp/pub\n  mp sub /tmp/pub";

  this._test = {
    parseArgs: parseArgs,
    parsePort: parsePort,
    parseType: parseType,
    validatePort: validatePort,
    validateType: validateType
  };

}).call(this);
