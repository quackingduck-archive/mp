# mp

The `mp` command line utility is like [curl] or [ncat] for [Message Ports]  (and [ZeroMQ] connections in general). It's a convenient way to experiment with different kinds of inter-process messaging patterns without having to write any code.

[curl]:http://curl.haxx.se
[ncat]:http://nmap.org/ncat
[Message Ports]:https://github.com/quackingduck/message-ports
[ZeroMQ]:http://www.zeromq.org

Here's an example of request/reply messaging:

First we open a reply socket on port 2000

    $ mp reply 2000
    - started reply socket on port 2000
    - waiting for request

Lines beginning with a `-` are log messages from the system. Now let's open another terminal and start a request socket connected to the same port.

    $ mp request 2000
    - started request socket on port 2000
    <

When you see a `<` that means that `mp` is waiting for you to type a message that will transmitted to the other end of the connection. Type anything and press enter.

    $ mp request 2000
    - started reply socket on port 2000
    < sup?
    - request sent
    - waiting for reply

Now switch back to the reply terminal and you should see

    $ mp reply 2000
    - started reply socket on port 2000
    - waiting for request
    - request received:
    > sup?
    <

Type a response and switch back to the other terminal

    $ mp request 2000
    - started reply socket on port 2000
    > sup?
    - message sent, waiting for response
    - reply received:
    > nm, u?
    <
