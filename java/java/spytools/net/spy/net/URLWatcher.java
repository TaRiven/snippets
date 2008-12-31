// Copyright (c) 2001  Dustin Sallings <dustin@spy.net>
//
// $Id: URLWatcher.java,v 1.2 2002/08/20 04:01:55 dustin Exp $

package net.spy.net;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import java.net.URL;

import java.io.IOException;

/**
 * URLWatcher watches URLs and provides access to the most recent data from
 * the URL.
 */
public class URLWatcher extends Thread {

	private static URLWatcher instance=null;

	// How long to sleep between updates
	private static final int NAP_TIME=60000;
	// maximum number of cleaner runs that can occur with no touches before
	// we shut down the thread.
	private static final int MAX_TOUCHLESS_RUNS=60;

	// This is where the items are stored.
	private HashMap pages=null;
	private int numRuns=0;
	private boolean notdone=true;

	// This lets it know when to give up
	private int recentTouches=0;
	private int touchlessRuns=0;

	/**
	 * Get an instance of URLWatcher.
	 */
	private URLWatcher() {
		super("URLWatcher");
		setDaemon(true);
		pages=new HashMap();
		start();
	}

	/**
	 * Get the static instance of URLWatcher.
	 *
	 * @return the URLWatcher
	 */
	public static synchronized URLWatcher getInstance() {
		if(instance==null || (!instance.isAlive())) {
			instance=new URLWatcher();
		}
		return(instance);
	}

	/**
	 * String me.
	 */
	public String toString() {
		int numPages=0;
		synchronized(pages) {
			numPages=pages.size();
		}
		return(super.toString() + " - " + numPages + " pages monitored, "
			+ numRuns + " runs");
	}

	/**
	 * Find out if this URLWatcher is watching a given URL.
	 *
	 * @param u the URL to test
	 * @return true if the URL is already being watched
	 */
	public boolean isWatching(URL u) {
		boolean rv=false;
		synchronized(pages) {
			rv=pages.containsKey(u);
		}
		return(rv);
	}

	/**
	 * Start watching the given URL.
	 * @param u The item to watch
	 */
	public void startWatching(URLItem u) {
		synchronized(pages) {
			// Don't add it if it's already there
			if(!pages.containsKey(u)) {
				pages.put(u.getURL(), u);
			}
		}
	}

	/**
	 * Update all the records.
	 */
	public void run() {
		while(notdone) {
			try {
				numRuns++;
				long now=System.currentTimeMillis();
				ArrayList toUpdate=new ArrayList();
				// Lock the array and see what needs updating
				synchronized(pages) {
					for(Iterator i=pages.values().iterator(); i.hasNext();) {
						URLItem ui=(URLItem)i.next();
						// Throw away anything that's not been updated
						// recently.
						if( (now-ui.getLastRequest()) > ui.getMaxIdleTime()) {
							i.remove();
						} else {
							toUpdate.add(ui);
						}
					}
				}
				// Now, we're unlocked, do the update
				for(Iterator i=toUpdate.iterator(); i.hasNext(); ) {
					URLItem ui=(URLItem)i.next();
					ui.update();
				}
				// Wait until the next run
				sleep(NAP_TIME);
			} catch(InterruptedException e) {
				e.printStackTrace();
				try {
					// Try to sleep another minute if we were interrupted
					sleep(60000);
				} catch(InterruptedException ie) {
					ie.printStackTrace();
				}
			}

			// Check to see if we're shutting down.
			watchTouches();

		} // not done
	}

	private void watchTouches() {
		// If nothing's touched it during this run, mark it as a touchless run
		if(recentTouches == 0) {
			touchlessRuns++;
		} else {
			// Otherwise, reset the touchless counter.
			touchlessRuns=0;
		}
		// If there have been more than MAX_TOUCHLESS_RUNS, shut down
		if(touchlessRuns > MAX_TOUCHLESS_RUNS) {
			shutdown();
		}
		recentTouches=0;
	}

	/**
	 * Instruct the URLWatcher to stop URLWatching.
	 */
	public void shutdown() {
		notdone=false;
	}

	/**
	 * Get the content (as a String) for a given URL.
	 *
	 * @param u The URL whose content we want
	 * @return The String contents, or null if none could be retreived
	 * @throws IOException if there was a problem updating the URL
	 */
	public String getContent(URL u) throws IOException {
		recentTouches++;
		URLItem ui=(URLItem)pages.get(u);
		// If we don't have one for this URL yet, create it.
		if(ui==null) {
			ui=new URLItem(u);
			startWatching(ui);
			// Load the content
			ui.update();
		}
		// Return the current content.
		return(ui.getContent());
	}

}
