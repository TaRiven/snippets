// Copyright (c) 2001  Dustin Sallings <dustin@spy.net>
//
// $Id: RSSStore.java,v 1.4 2002/08/16 07:28:44 dustin Exp $

package net.spy.rss;

import java.util.*;
import net.spy.net.*;

/**
 * Take care of the relationships with all the RSS vendors.
 */
public class RSSStore extends Thread {

	// Don't let them idle more than an hour
	private static final int MAX_IDLE_TIME=3600000;

	private HashMap sites=null;
	private boolean notdone=true;
	private int runs=0;

	/**
	 * Get an instance of RSSStore.
	 */
	public RSSStore() {
		super("RSSStore");
		setDaemon(true);
		sites=new HashMap();
	}

	/**
	 * Get a String telling about this thing.
	 */
	public String toString() {
		int numSites=0;
		synchronized(sites) {
			numSites=sites.size();
		}
		return(super.toString() + " - "
			+ numSites + " sites watched, " + runs + " runs");
	}

	/**
	 * Update all the thingies.
	 */
	public void run() {
		// Flip through the list every five minutes and get it updated.
		while(notdone) {
			try {
				runs++;
				long now=System.currentTimeMillis();
				// Update and queue removals
				ArrayList toUpdate=new ArrayList();
				synchronized(sites) {
					for(Iterator i=sites.values().iterator(); i.hasNext(); ) {

						RSSItem ri=(RSSItem)i.next();
						// Throw away anything that's too old, otherwise,
						// get ready to update it
						if( (now-ri.lastRequest()) > MAX_IDLE_TIME) {
							i.remove();
						} else {
							toUpdate.add(ri);
						}
					}
				}
				for(Iterator i=toUpdate.iterator(); i.hasNext(); ) {
					RSSItem ri=(RSSItem)i.next();
					ri.update();
				}
				sleep(5*60*1000);
			} catch(Exception e) {
				System.err.println("RSSStore error:  " + e);
				e.printStackTrace();
			}
		}
		System.err.println("RSS Thread shutting down.");
	}

	/**
	 * Prepare for a shutdown.
	 */
	public void shutdown() {
		// Double negative!
		notdone=false;
	}

	/**
	 * Get the content for a URL.
	 */
	public String getContent(String url) {
		RSSItem ri=(RSSItem)sites.get(url);
		// If we don't have one for this URL yet, get one.
		if(ri==null) {
			// Lock the sites hash while we create this new one.
			synchronized(sites) {
				ri=new RSSItem(url);
				sites.put(url, ri);
			}
			// Tell it to get its shit.
			ri.update();
		}
		return(ri.getContent());
	}

}
