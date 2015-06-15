###
# RSA Encryption Library for OChat.
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

class RSAKey
  p: null
  q: null
  n: null
  e: 0
  d: null

  constructor: (seed, length, exponent) ->
    factor_size = length >> 1;
    @e = exponent;
    e_big = new BigInteger(exponent);

    loop
      loop
        @p = new BigInteger(factor_size, 1, seed);
        break if @p.subtract(BigInteger.ONE).gcd(e_big).compareTo(BigInteger.ONE) is 0 and @p.isProbablePrime(10);
      loop
        @q = new BigInteger(factor_size, 1, seed);
        break if @q.subtract(BigInteger.ONE).gcd(e_big).compareTo(BigInteger.ONE) is 0 and @p.isProbablePrime(10);
      phi = @p.subtract(BigInteger.ONE).multiply @q.subtract(BigInteger.ONE);
      if phi.gcd(e_big).compareTo(BigInteger.ONE) is 0
        @n = @p.multiply @q;
        @d = e_big.modInverse(phi)
        break;

  getPublic: -> new RSAPublicKey(@n, @e);
  getPrivate: -> new RSAPrivateKey(@n, @d);

class RSAPublicKey
  n: null
  e: 0

  constructor: (n, e) ->
    @n = if typeof(n) is 'string' new BigInteger(n, 16) else n;
    @e = if typeof(e) is 'string' parseInt(e, 16) else e;

  encrypt: (msg) ->
    msg = if typeof(msg) is 'string' new BigInteger(msg, 16) else msg;
    if msg? and @e? and @n? msg.modPow(@e, @n).toString(16) else null;

class RSAPrivateKey
  n: null
  d: null

  constructor: (n, d) ->
    @n = if typeof(n) is 'string' new BigInteger(n, 16) else n;
    @d = if typeof(d) is 'string' new BigInteger(d, 16) else d;

  decrypt: (cypher) ->
    cypher = if typeof(cypher) is 'string' new BigInteger(cypher, 16) else cypher
    if cypher? and @d? and @n? cypher.modPow(@d, @n).toString(16) else null;
