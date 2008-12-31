/*
 * Copyright (c) 2002  Dustin Sallings
 *
 * $Id: AllTests.java,v 1.1 2002/08/12 21:59:36 dustin Exp $
 */

package net.spy.test;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

/**
 * Test everything.
 */
public class AllTests extends TestSuite {

    /**
     * Get an instance of AllTests.
     */
    public AllTests(String name) {
        super(name);
    }

	/**
	 * Get this test suite.
	 */
	public static Test suite() {
		TestSuite rv=new TestSuite();
		rv.addTest(CacheTest.suite());
		rv.addTest(PoolTest.suite());
		return(rv);
	}

	/**
	 * Run this test.
	 */
	public static void main(String args[]) {
		junit.textui.TestRunner.run(suite());
	}

}
