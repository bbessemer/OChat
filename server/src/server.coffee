###
# OChat - simple and secure JavaScript API for text chat.
# Server-side portion, main server module.
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

http = require 'http'
fs = require 'fs'

conf = JSON.parse fs.readFileSync __dirname + '/config.json', {encoding: 'utf8'}
boards = new Object;

for fn in fs.readdirSync conf.homedir
  if fs.statSync(conf.homedir + '/' + fn).isDirectory()
    fs.readFile conf.homedir + '/' + fn + '/board.json', {encoding: 'utf8'}, (err, data) ->
      if err then throw err
      boards[fn] = new MsgBoard(fn, JSON.parse data);

server = http.createServer ->
