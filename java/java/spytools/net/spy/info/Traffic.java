// Copyright (c) 2000  Dustin Sallings <dustin@spy.net>
//
// $Id: Traffic.java,v 1.2 2000/06/16 20:08:37 dustin Exp $

package net.spy.info;

import java.util.*;

import net.spy.*;
import net.spy.net.*;

/**
 * Get Traffic info.
 */

public class Traffic extends Info {

	/**
	 * Get an Traffic object.
	 *
	 * @param geo_loc The Yahoo geographical location string.
	 */
	public Traffic(String geo_loc) {
		super();
		this.arg = geo_loc;
	}

	/**
	 * Get an unitialized Traffic object.
	 */
	public Traffic() {
		super();
	}

	public String toString() {
		String ret="";
		try {
			if(error) {
				ret=get("info");
			} else {
				ret=get("ERROR");
			}
		} catch(Exception e) {
			// Who cares.
		}
		return(ret);
	}

	protected void parseInfo() throws Exception {
		if(hinfo==null) {
			hinfo=new Hashtable();
			hinfo.put("geo_loc", arg);
			getInfo();
			String lines[]=SpyUtil.split("\n", info);
			int section=0;
			String local_info = "";
			for(int i=0; i<lines.length; i++) {
				if(lines[i].startsWith("Sponsored By")) {
					i++;
					section=1;
					error=false;
				} else if(lines[i].startsWith("Alert Me") && section==1) {
					section=2;
				}

				// We've figured out what section we're in, now let's look
				// at the data.
				if(section==1) {
					System.out.println("Adding:  " + lines[i]);
					local_info+=lines[i] + "\r\n";
				}
			}
			if(error) {
				String error_string="Unable to get Traffic info.  "
					+ "Invalid geo loc?";
				hinfo.put("ERROR", error_string);
			} else {
				local_info=local_info.trim();
				hinfo.put("info", local_info);
			}
		} // if there's a need to find it at all.
	}

	protected void getInfo() throws Exception {
		if(info==null) {
			String url=
				"http://traffic.yahoo.com/traffic/";
			url += arg;
			hinfo.put("URL", url);
			HTTPFetch f = new HTTPFetch(url);
			info=f.getStrippedData();
		}
	}

	public static void main(String args[]) throws Exception {
		Traffic f = new Traffic(args[0]);
		System.out.println("Info:\n" + f);
		System.out.println("Info (XML):\n" + f.toXML());
	}
}
