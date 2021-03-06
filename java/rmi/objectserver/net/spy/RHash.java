// Copyright (c) 1999 Dustin Sallings <dustin@spy.net>
// $Id: RHash.java,v 1.1 1999/10/20 03:02:03 dustin Exp $

package net.spy;

import java.rmi.Naming; 
import java.rmi.RemoteException; 

import java.util.*;

public class RHash { 

	private String rhashserver;
	private RObject obj;

	public RHash(String server) {
		rhashserver = server;
		obj = getobject();
	}

	protected void finalize() throws Throwable {
		obj = null;
		super.finalize();
	}

	public Object get(String name) {
		Object o;
		try {
			o = obj.getObject(name);
		} catch(Exception e) {
			e.printStackTrace();
			o = null;
		}
		return(o);
	}

	public void put(String name, Object o) {
		try {
			obj.storeObject(name, o);
		} catch(Exception e) {
			e.printStackTrace();
		}
	}

	private RObject getobject() {
		try {
			RObject o = new RObjectImpl();
			o = (RObject)Naming.lookup(rhashserver);
			return(o);
		} catch(Exception e) {
			return(null);
		}
	}
}
