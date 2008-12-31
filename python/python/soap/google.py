#!/usr/bin/env python
# Copyright (c) 2002  Dustin Sallings <dustin@spy.net>
# $Id: google.py,v 1.4 2002/04/16 05:30:22 dustin Exp $

from __future__ import generators

import sys
import SOAP

class ResultsNotReady:
	"""Exception raised when attempting to use search results
	before they're ready."""
	pass

class GoogleSearch:

	# This is my key
	myKey='2hOO7zk9TTDrPe0fpnxR0Yv/5K66pVHX'

	soapfalse=SOAP.booleanType(0)
	soaptrue=SOAP.booleanType(1)

	def __init__(self):
		"""Get a new google search thing."""
		self.server=SOAP.SOAPProxy("http://api.google.com/search/beta2",
			namespace='urn:GoogleSearch')
		self.results=None

	# This makes it easy to quote the strings
	s=SOAP.stringType

	def doSearch(self, query, filter=1, restrict='', safeSearch=0,
		lr='', ie='', oe=''):
		"""Perform a google search."""

		if filter: filter=GoogleSearch.soaptrue
		else: filter=GoogleSearch.soapfalse

		if safeSearch: safeSearch=GoogleSearch.soaptrue
		else: safeSearch=GoogleSearch.soapfalse

		self.query=query
		self.filter=filter
		self.restrict=restrict
		self.safeSearch=safeSearch
		self.lr=lr
		self.ie=ie
		self.oe=oe

		self._performQuery(0)

	def _performQuery(self, startId):

		self.results=self.server.doGoogleSearch(
			GoogleSearch.s(GoogleSearch.myKey),
			GoogleSearch.s(self.query), startId, 10, self.filter,
			GoogleSearch.s(self.restrict), self.safeSearch,
			GoogleSearch.s(self.lr), GoogleSearch.s(self.ie),
			GoogleSearch.s(self.oe))

	# Verify we have search results ready
	def __checkResults(self):
		if not self.results:
			raise ResultsNotReady

	def __iter__(self):
		"""Iterate over the search results."""
		self.__checkResults()

		lastId=0
		count=0
		while 1:
			currentId=self['startIndex']
			startId=currentId

			currentId=startId
			for r in self['resultElements']:
				yield currentId, r
				currentId+=1
			# Gotta know when to stop
			startId=self['endIndex']
			if startId == lastId or (not startId == (lastId+10)):
				raise StopIteration
			lastId=startId

			# Safety check, make sure we don't do more than 100 calls ever
			count+=1
			if count>100:
				print "TOO MANY QUERIES!"
				raise StopIteration

			# Reperform query
			self._performQuery(startId)

	def __getitem__(self, which):
		self.__checkResults()
		return self.results[which]

if __name__ == '__main__':
	query=sys.argv[1]
	g=GoogleSearch()
	g.doSearch(query)

	# Print meta information:
	extra=''
	if g['estimateIsExact']:
		extra=' (exact)'
	print "Estimated results for " + `query` + ":  " \
		+ `g['estimatedTotalResultsCount']` + extra
	if len(g['searchTips'])>0:
		print "Tips:  " + g['searchTips']
	if len(g['searchComments']) > 0:
		print "Comments:  " + g['searchComments']
	print "Results:"
	for r in g:
		try:
			print "\t" + `r[0]` + ": " + r[1]['URL'] + " - " + r[1]['title']
		except UnicodeError:
			print "\t" + `r[0]` + ": " + r[1]['URL'] + ' - <UNICODE ERROR>'

