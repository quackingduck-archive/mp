(function() {
  var ansi, im, interactiveMode, longName, mp, name, portExp, printUsageAndExitWithError, typeAliases, typeExp, usage, validatePort, validateType, _ref, _ref2;
  mp = require('message-ports');
  this.run = function(args) {
    var port, type;
    type = args.shift();
    if (typeAliases[type] != null) {
      type = typeAliases[type];
    }
    validateType(type);
    port = args.shift();
    validatePort(port);
    port = parseInt(port);
    if (args.length === 0) {
      return interactiveMode(type, port);
    } else {
      return printUsageAndExitWithError();
    }
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
  typeAliases = {
    request: 'req',
    reply: 'rep',
    publish: 'pub',
    subscribe: 'sub'
  };
  validateType = function(type) {
    if (!typeExp.test(type)) {
      console.log("" + type + " isn't a valid message port type");
      return printUsageAndExitWithError();
    }
  };
  validatePort = function(port) {
    if (!portExp.test(port)) {
      console.log("" + port + " isn't a valid port number");
      return printUsageAndExitWithError();
    }
  };
  typeExp = /^rep|req|push|pull|pub|sub$/;
  portExp = /^\d+$/;
  ansi = {
    gray: '\x1b[0;37m',
    reset: '\x1b[m'
  };
  printUsageAndExitWithError = function() {
    console.log(usage);
    return process.exit(1);
  };
  usage = "usage: mp reply 2000";
}).call(this);
