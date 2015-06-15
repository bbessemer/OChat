## DO NOT USE THIS FILE ##

###
# bigmath - library of basic mathematical operations for extremely large
# numbers of the cryptographic variety
# Part of OChat.
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

# This is NOT designed to be a full large-number math library. It's designed
# for cryptography, and so only supports positive integers of arbitrary length.
# These integers are represented as JavaScript Uint16Arrays, which are
# LITTLE-ENDIAN, i.e., the first number is the least significant. (Normally I
# find little-endianness to be extremely unintuitive, but in this case where
# array indices must be dealt with, it's significantly simpler.)
# 
# The array elements are only 16-bit integers because JavaScript only supports
# native integers of up to 32 bits -- multiplying two 32-bit integers can yield
# up to 64 bits in the result.

exports = this;
exports.BigMath = {
	
	add: (a, b) ->
		i = 0;
		while i < Math.max(a.length, b.length)
			if !a[i]? then a[i] = 0;
			if !b[i]? then b[i] = 0;
			r = a[i] + b[i] + c;
			result[i] += (r >>> 0) % 65536;
			c = r >>> 16;	# carry
		return new Uint16Array(result);
	# END
	
	mult: (a, b) ->
		# Basically this does long multiplication with a base of 65,536 (2^16).
		result = [];
		for x, i in a
			for y, j in b
				if !result[i+j]? then result[i+j] = 0;
				r = x * y + c;
				result[i+j] += (r >>> 0) % 65536;
				c = r >>> 16;	# carry
			c = 0;
		return new Uint16Array(result);
	# END
	
	power: (x, n) ->
		# Basic recursive exponentiation-by-squaring algorithm
		# Only supports machine-size positive integer powers
		n = n | 0;
		if n < 0 return NaN;
		else if n == 0 return new Uint16Array([1]);
		else if n == 1 return x;
		else if n == 2 return @mult(x, x);
		else if n % 2 == 0 return @power(@mult(x, x), n/2);
		else return @mult(x, @power(@mult(x, x), (n-1)/2);
	# END
	
	
	
}