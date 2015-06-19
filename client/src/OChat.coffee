###
# OChat - simple and secure JavaScript API for text chat.
# Client-side portion.
#
# Copyright (C) 2015, Ember Group. All rights reserved.
# Licensed under zlib Licence with one modification (see below).
#
# This software is provided 'as-is', without any express or implied
# warranty. In no event will the authors be held liable for any damages
# arising from the use of this software.
#
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgement in the product documentation, including
#    the name of the original product and the names of the authors, is required.
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
# 3. This notice may not be removed or altered from any source distribution.
###

# This is here just to help us remember what goes into the OChat object.
# It also happens to match what the server will return to an unauthorised user.

# static
class OChat

  @authorized: false
  @username: ""
  @token: ""
  @server: ""
  @board: ""
  @lastMessageId: 0
  @messageLog: []
  @signingKey: null
  @privateKey: null
  @verificationKeys: []


  @messagesReceivedHandlers = [];
  @addMessagesReceivedHandler = (func) ->
    @messagesReceivedHandlers.push(func) - 1;
  @removeMessagesReceivedHandler = (toRemove) ->
    if typeof(toRemove) is 'number'
      @messagesReceivedHandlers.splice(toRemove, 1);
    else
      i = 0;
      until i is -1
        @messagesReceivedHandlers.splice(i = @messagesReceivedHandlers.indexOf(toRemove), 1);

  @messagesReceived = (messages) ->
    for handle in @messagesReceivedHandlers
      handle message if typeof(handle) is 'function';

  @refreshToken = ->
    if @privateKey? and @signingKey?
      xhr = new XMLHttpRequest;
      xhr.open 'GET', '#{@server}#{@board}?get=token&token=#{@token}', true
      xhr.onreadystatechange = ->
        if OChat.privateKey? and OChat.signingKey? and @readystate is 4 and @status is 200
          OChat.token = OChat.privateKey.decrypt @responseText
      xhr.send()

  @send = (message) ->
    time = new Date;

    # Geolocation is complicated because (a) not all browsers support it and
    # (b) the user can refuse permission.
    _location = new Object;
    waitingForLoc = false;
    if navigator.geolocation

      # The usual way of handling asynchronous things synchronously. It's kind
      # of messy, but it seems to be the only way.
      waitingForLoc = true;
      navigator.geolocation.getCurrentPosition (p) ->
        _location.lat = p.coords.latitude;
        _location.lng = p.coords.longitude;
        waitingForLoc = false;

      # CoffeeScript's syntax makes this confusing, but the following line is
      # the second parameter to getCurrentPosition(), which is supposed to be an
      # error-handling function. The only purpose of this function is to tell
      # the chat client that we are no longer waiting on the user's location,
      # because we tried to get it and failed.
      , -> waitingForLoc = false;
    else _location = null;
    while waitingForLoc
      continue;

    # Create an object containing the message's text, timestamp, and other
    # metadata.
    message_obj =
      sentBy: @username
      timestamp: time.getTime()
      # The multiplication by -60 is done for compatibility with the Google Maps
      # Time Zone API.
      timezone: -60*time.getTimezoneOffset()
      sentFrom: _location
      text: message
      sent: false

    xhr = new XMLHttpRequest;
    xhr.open 'POST', '#{@server}#{@board}?token=#{@token}', true;

    # The server will return code 200 when the message is posted.
    # The server will return a new token, encrypted with the user's public key.
    xhr.onreadystatechange = ->
      if @readystate is 4 and @status is 200
        message_obj.sent = true;
        OChat.token = OChat.privateKey.decrypt @responseText;

    cypher = @signingKey.sign hexify JSON.stringify message_obj
    xhr.send JSON.stringify
      u: @username
      c:
        if typeof cypher is 'string' then hex2b64 cypher;
        else hex2b64 x for x in cypher;

    # Add it to the message log
    @messageLog.push(message_obj);

    # ...and we're done. To stop CoffeeScript from doing something weird, we...
    return;
  # END OChat.send()

  @check: ->
    OChat.checking = true;
    xhr = new XMLHttpRequest;
    xhr.open 'GET', '#{@server}#{@board}?get=#{@lastMessageId}+new&token=#{@token}', true;

    xhr.onreadystatechange = ->
      if @readystate is 4 and @status is 200
        raw = JSON.parse @responseText;
        OChat.token = raw.token;
        if raw.msgs?
          OChat.messageLog.concat(
            messages = for msg in raw.msgs
              JSON.parse OChat.verificationKeys[msg.u].decrypt(
                if typeof msg.c is 'string' then b64tohex msg.c;
                else b64tohex x for x in msg.c
              );
          );
          OChat.messagesReceived(messages);
      OChat.checking = false;
    # END xhr.onreadystatechange()

    xhr.send()
  # END OChat.check()

# END static class OChat

global.OChat = OChat;
