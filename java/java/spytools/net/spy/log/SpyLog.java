/*
 * Copyright (c) 1999 Dustin Sallings
 *
 * $Id: SpyLog.java,v 1.11 2002/07/10 04:25:48 dustin Exp $
 */

package net.spy.log;

import java.util.Vector;

/**
 * The Spy Asyncrhonous logger.
 * <p>
 * SpyLog is an implementation of an asynchronous logger that allows one to
 * have multiple points of input into a single queueing system that runs in
 * its own thread recording the logs.
 * <p>
 * If this doesn't sound immediately obvious to you, imagine having a
 * transactional system that logs into a database without slowing down the
 * transactions.  SpyLog gives you the ability to get a log entry out of your
 * way quickly, to be permanently recorded later.
 */

public class SpyLog extends Object {
	private SpyLogQueue queue=null;
	private static boolean initialized = false;
	private static Vector flushers=null;
	private String queue_name=null;

	/**
	 * Instantiate a SpyLog interface for the given queue name with the
	 * default flusher.
	 */
	public SpyLog(String queue_name) {
		super();

		this.queue_name=queue_name;

		// Important to initialize only once, this sets up all the static
		// variables including the cleanup thread.
		if(initialized == false) {
			initialize();

			// If this is initialization, and we don't have a flusher, make
			// one.
			synchronized(flushers) {
				// Default flusher.
				if(flushers.size()==0) {
					SpyLogFlusher flusher = new SpyLogFlusher(queue_name);
					addFlusher(flusher);
				}
			}
		}

		// Grab a queue object
		queue=new SpyLogQueue(queue_name);
	}

	/**
	 * Instantiate a SpyLog entry with an alternative log flusher.  An
	 * alternative log flusher may log into a SQL database, or to a pager,
	 * or email, etc...
	 */
	public SpyLog(String queue_name, SpyLogFlusher f) {
		super();

		this.queue_name=queue_name;

		// Important to initialize only once, this sets up all the static
		// variables including the cleanup thread.
		if(initialized == false) {
			initialize();
		}

		// The log flusher object.
		addFlusher(f);

		// Grab a queue object
		queue=new SpyLogQueue(queue_name);
	}

	/**
	 * Add another log flusher to the pool.
	 */
	public void addFlusher(SpyLogFlusher f) {
		synchronized(flushers) {
			try {
				f.start();
			} catch(IllegalThreadStateException e) {
				e.printStackTrace();
			}
			flushers.addElement(f);
		}
	}

	/**
	 * Remove the given flusher.
	 */
	public void removeFlusher(SpyLogFlusher f) {
		synchronized(flushers) {
			flushers.removeElement(f);
		}
	}

	/**
	 * Log an entry.
	 *
	 * @param msg SpyLogEntry object to be logged.
	 */
	public void log(SpyLogEntry msg) {
		queue.addToQueue(msg);
	}

	private static synchronized void initialize() {
		// Do this soon, we don't want anything else causing this to happen.
		initialized = true;

		if(flushers==null) {
			flushers=new Vector();
		}
	}
}
