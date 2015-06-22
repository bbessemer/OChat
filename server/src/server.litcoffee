# OChat

A simple and secure JavaScript API for text chat.
Server-side portion, main server module.

## Licence

Copyright &copy; 2015, Ember Group. All rights reserved.

Licensed under zlib Licence with one modification (see below).

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
claim that you wrote the original software. If you use this software
in a product, an acknowledgement in the product documentation, including
the name of the original product and the names of the authors, is required.

2. Altered source versions must be plainly marked as such, and must not be
misrepresented as being the original software.

3. This notice may not be removed or altered from any source distribution.

## Basic Setup

Import some modules.

    http = require 'http'
    url = require 'url'
    fs = require 'fs'
    auth = require './auth.js'
    MsgBoard = require './msgboard.js'

Read the configuration.

    conf = JSON.parse
      fs.readFileSync __dirname + '/config.json', {encoding: 'utf8'}

The `boards` object maps the boards' names (strings, usually formatted like
`group#board`) to `MsgBoard` objects. Initialise it and populate it based on the
subdirectories in the OChat home directory.

    boards = new Object;
    for fn in fs.readdirSync conf.homedir
      if fs.statSync(conf.homedir + '/' + fn).isDirectory()
        fs.readFile conf.homedir + '/' + fn + '/board.json', {encoding: 'utf8'}, (err, data) ->
          if err then throw err
          boards[fn] = new MsgBoard(fn, JSON.parse data);

## Server Request Handler

    server = http.createServer (req, res) ->

### URL Parsing

Now inside the handler, parse the requested URL with Node's URL parser...

      _url = url.parse request.url

...which, unfortunately, can only do so much. Node's parser doesn't recognise
query strings after the `#` character. We still have to:

Concatenate the `path` and `hash` sections of the URL.

      path = _url.path + _url.hash

Remove the pre-defined prefix from the path.

      noPrefix = @replace conf.prefix ''

Separate the un-prefixed path at the question mark.

      matches = noPrefix.match /[^\?]*/

If the board (the first part of the path) already exists, set the `board`
variable to point to it.

      [board, query] = [
        if boards[matches[0]] then boards[matches[0]]

Otherwise, create the board and add it to the `boards` object, *then* set the
`board` variable to point to it.

        else boards[matches[0]] = new MsgBoard(matches[0]).save()

Node's URL parser is good for parsing query strings into JavaScript objects, so
use it to parse the section that we determined to be the query string.

        url.parse '?' + matches[1], true
      ]

### Interaction with `MsgBoard`

Don't do anything if the token is not valid. `auth()` will return the username
if it is, and `null` if it isn't. (The equals sign is *not* an equality check.
I'm just saving typing by doing the assignment in the `if` statement.)

      if username = auth query.token

`GET` indicates to retrieve messages from the server.

        if req.method is 'GET'

Initialise the `reply` object.

          reply = new Object

In `recent` mode, the server is allowed to define how many messages are considered
'recent'. A single negative argument to `MsgBoard::subscribe()` gets the *x* most
recent messages.

          if query.get is 'recent'
            reply.msgs = board.subscribe -1*conf.recent

If not in recent mode, parse the `get` section of the query string to get the
range of messages to return, then actually get those messages. A single positive
argument to `MsgBoard::subscribe()` gets messages from that message ID to the
end of the log.

          else
            [from, to] = query.get.split '-'
            if to is 'now'
              reply.msgs = board.subscribe parseInt from
            else
              reply.msgs = board.subscribe parseInt(from), parseInt(to)

Generate a new token for the user.

          reply.token = auth.newToken username

Write the server response.

          replyString = JSON.stringify reply
          res.writeHead 200,
            'Content-Type': 'application/json'
            'Content-Length': replyString.length
          res.write replyString

`POST` means to publish messages to the server.

        else if req.method is 'POST'

Data is sent as a stream, so we need to asynchronously concatenate it.

          body = ''
          req.on 'data', (data) ->
            body += data

If someone's trying to upload more than 100 kB of messages, they're most likely
a DDoSer. Kill their connection.

            req.connection.destroy() if body.length > 1e5

When all the data is uploaded, parse it and post it to the message board.

          req.on 'end', ->
            board.publish JSON.parse body

Respond with a new token for the user, which will be 128 bits or 128/4 = 32
digits of hexedecimal, encoded as text. The HTTP status 201 means 'created', i.e.,
the message was posted.

          res.writeHead 201,
            'Content-Type': 'text/plain'
            'Content-Length': 32
          res.write auth.newToken username

No other HTTP method besides `GET` or `POST` should be sent by a compliant OChat
client. If we're getting anything else, like, say, `DELETE`, just return a 405
(Method Not Allowed).

        else res.writeHead 405, 'Method Not Allowed'

This `else` statement goes all the way back to the authentication check at the
beginning: if the token is invalid, return a 403 Forbidden. (A 401 Unauthorised
requires a WWW-Authenticate header to be returned; since we don't use WWW-Authenticate,
we don't use 401.) The response body will be the URL of the server's login page,
which is in the configuration object.

      else
        res.writeHead 403, 'Access Denied',
          'Content-Type': 'text/plain'
          'Content-Length': conf.loginURL.length
        res.write conf.loginURL

No matter what we wrote to the response, it's now over. Void the last call to
avoid CoffeeScript implicit return.

      void res.end()

## Final Stuff

Tell the server to listen on the port defined in the configuration.

    .listen conf.port

Export the server object and the configuration.

    module.exports = server
    global.conf = conf

**THE END**
