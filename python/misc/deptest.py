#!/usr/bin/env python
"""

Copyright (c) 2005  Dustin Sallings <dustin@spy.net>
"""
# arch-tag: 0FC88FCC-E29E-4995-B026-32D806F0538F

import unittest
import deporder

class DepTestCase(unittest.TestCase):

    def setUp(self):
        self.do=deporder.DependencyOrderer()

    def __addFile(self, f):
        self.do.add(deporder.DepFile("test/dep/" + f))

    def assertFilenames(self, fn):
        self.assertEquals(["test/dep/" + f for f in fn],
            [f.filename for f in self.do.getNodes()])

    def testOne(self):
        """Test just the base file."""
        self.__addFile("basefile")
        self.assertFilenames(["basefile"])

    def testOneFailure(self):
        """Test just the nonresolvable file."""
        self.__addFile("nonresolvable")
        try:
            self.do.getNodes()
        except deporder.NotPlaced, e:
            self.assertEquals(["brokenness"], e.deps)

    def testInjectedNode(self):
        """Test just the nonresolvable file."""
        self.__addFile("nonresolvable")

        self.do.add(deporder.Node(['brokenness']))
        self.assertEquals(['brokenness', 'nothing'],
            [iter(n.provides).next() for n in self.do.getNodes()])

    def testSequence(self):
        """Test a bunch of files."""
        for f in ['somefile', 'anotherfile', 'dependent', 'basefile']:
            self.__addFile(f)
        self.assertFilenames(["basefile", 'anotherfile', 'somefile',
            'dependent'])

    def testMultiProvides(self):
        """Test files that provide multiple things."""
        for f in ('multiprovreq', 'multiprov'):
            self.__addFile(f)
        self.assertFilenames(['multiprov', 'multiprovreq'])

    def testAllFailure(self):
        """Test all files (including broken)."""
        for f in ['nonresolvable', 'somefile', 'anotherfile', 'dependent',
            'basefile']:
            self.__addFile(f)
        try:
            f=self.do.getNodes()
            self.fail("Expected not placed, got " + `f`)
        except deporder.NotPlaced, e:
            self.assertEquals(["brokenness"], e.deps)

if __name__ == '__main__':
    unittest.main()
