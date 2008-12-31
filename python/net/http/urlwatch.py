#!/usr/bin/env python
"""

Copyright (c) 2002  Dustin Sallings <dustin@spy.net>
$Id: urlwatch.py,v 1.1 2002/04/26 09:04:30 dustin Exp $
"""

import anydbm
import urllib2
import base64
import md5

class UrlHasher:

	def __init__(self):
		pass

	def getUrlHash(self, url):
		data=self._getUrlData(url)
		m=md5.new()
		m.update(data)
		d=m.digest()
		e=base64.encodestring(d).rstrip()
		return e

	def _getUrlData(self, url):
		u=urllib2.urlopen(url)
		s=''.join(u.readlines())
		return s

class UrlWatcher:

	def __init__(self):
		self.d=anydbm.open('urldb', 'c')
		self.uh=UrlHasher()

	def __del__(self):
		self.d.close()

	def checkUrl(self, url):
		hc=self.uh.getUrlHash(url)
		oldhc=''
		try:
			oldhc=self.d[url]
		except KeyError:
			pass

		if oldhc!=hc:
			self.d[url]=hc
			print url + ' has changed: was ' + oldhc + ' now is ' + hc

if __name__ == '__main__':
	uw=UrlWatcher()

	uw.checkUrl('http://bleu.west.spy.net/')
