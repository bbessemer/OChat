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
OChat =
  authorized: false
  username: ""
  token: ""
  server: ""
  board: ""
  lastMessageId: 0
  messageLog: []
  signingKey: null
  verificationKeys: []

oChat_init = (serverUri, token) ->

  # When the client loads the page, the server has no idea who he/she is, so the
  # client must send an authentication token to the server. If authorised (e.g.,
  # s/he is in the group), the server will respond with a JSON file containing
  # his/her username and the verification keys for everyone else in the group.
  # Transmitting the user's signing key over the network should be done as
  # little as possible, so it is stored in a cookie and only requested from the
  # server if lost.
  xhr = new XMLHttpRequest;
  xhr.open "GET", serverUri + "?get=setup&token=" + token, true;
  xhr.onreadystatechange = ->
    OChat = JSON.parse @responseText if @readystate is 4 and @status is 200;

    # Replace the string keys in the JSON with RSAPublicKey objects.
    for key in OChat.verificationKeys
      key = new RSAPublicKey(b64tohex key.b64, 0x10001, key.owner);
    return;
  xhr.send();

  # TODO: check for the signing key and retrieve if missing.

  OChat.send = (message) ->
    time = new Date;

    # Geolocation is complicated because (a) not all browsers support it and
    # (b) the user can refuse permission.
    location = new Object;
    waitingForLoc = false;
    if navigator.geolocation

      # The usual way of handling asynchronous things synchronously. It's kind
      # of messy, but it seems to be the only way.
      waitingForLoc = true;
      navigator.geolocation.getCurrentPosition (p) ->
        location.lat = p.coords.latitude;
        location.lng = p.coords.longitude;
        waitingForLoc = false;

      # CoffeeScript's syntax makes this confusing, but the following line is
      # the second parameter to getCurrentPosition(), which is supposed to be an
      # error-handling function. The only purpose of this function is to tell
      # the chat client that we are no longer waiting on the user's location,
      # because we tried to get it and failed.
      , -> waitingForLoc = false;
    else location = null;
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
      sentFrom: location
      text: message
      sent: false

    xhr = new XMLHttpRequest;
    xhr.open "POST", @server + @board + '?token=' + @token, true;

    # The server will return code 200 when the message is posted.
    # The responseText is irrelevant, preferably servers should return none.
    xhr.onreadystatechange = ->
      if @readystate is 4 and @status is 200 then message_obj.sent = true;

    # The real magic happens in this sequence of six(!) nested function calls.
    xhr.send JSON.stringify
      username: @username
      token: @token
      cyphertext: hex2b64 @signingKey.sign hexify JSON.stringify message_obj
    # ))))}));  -- That's what it would look like with parens.

    # Add it to the message log
    messageLog.push(message_obj);

    # ...and we're done. To stop CoffeeScript from doing something weird, we...
    return;
  # END OChat.send()
