#!/usr/bin/env python
"""

Copyright (c) 2002  Dustin Sallings <dustin@spy.net>
$Id: searchindex.py,v 1.1 2002/04/16 05:30:24 dustin Exp $
"""

import anydbm
import time
import sys
import google

class MatchPrinter:

	def __init__(self, query):
		self.seenUrl=None
		self.query=query

	def match(self, type, value):
		if type=='url':
			if not self.seenUrl:
				print "New URLs for ``" + self.query + "'':"
				self.seenUrl=1
			print "\t+ " + value['URL']
		else:
			print 'New ' + type + ' for ``' + self.query + "'':  " + value

class SearchWatcher:
	"""Watch a set of search terms for result changes."""

	def __init__(self):
		self.db=anydbm.open("searchdb", "c")

	def __checkTips(self, g, query, matchCallback):
		tips=g['searchTips']
		try:
			oldtips=self.db[query + '/tips']
		except KeyError:
			oldtips=''
		if tips != oldtips:
			self.db[query+'/tips']=tips
			matchCallback('tips', tips)

	def __checkComments(self, g, query, matchCallback):
		comments=g['searchComments']
		try:
			oldcomments=self.db[query + '/comments']
		except KeyError:
			oldcomments=''
		if comments != oldcomments:
			self.db[query+'/comments']=comments
			matchCallback('tips', tips)

	def checkQuery(self, query, matchCallback=None):

		if matchCallback==None:
			mp=MatchPrinter(query)
			matchCallback=mp.match

		g=google.GoogleSearch()
		g.doSearch(query)

		# Check tips and comments
		self.__checkTips(g, query, matchCallback)
		self.__checkComments(g, query, matchCallback)

		for rs in g:
			idx,r = rs
			key=query+'/results ' + r['URL']
			if not self.db.has_key(key):
				self.db[key]=str(time.time)
				matchCallback('url', r)

if __name__=='__main__':
	sw=SearchWatcher()
	for q in sys.argv[1:]:
		sw.checkQuery(q)
