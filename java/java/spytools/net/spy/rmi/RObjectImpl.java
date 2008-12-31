// Copyright (c) 1999 Dustin Sallings <dustin@spy.net>
// $Id: RObjectImpl.java,v 1.4 2000/06/20 07:14:36 dustin Exp $

package net.spy.rmi;

import java.rmi.Naming;
import java.rmi.RemoteException;
import java.rmi.RMISecurityManager;
import java.rmi.server.UnicastRemoteObject;

import java.util.*;
import java.lang.*;
import java.io.*;

public class RObjectImpl extends UnicastRemoteObject implements RObject {

	// Number of hash directory levels.
	public int levels = 256;
	// Base directory for hashing
	public String basedir = "/tmp/rcache";

	public RObjectImpl() throws RemoteException {
		super();
	}

	public RObjectImpl(String basedir) throws RemoteException {
		super();
		this.basedir=basedir;
	}

    public void storeObject(String name, Object o) throws RemoteException {
		int hash, subhash;
		String pathto;
		File f;

		System.out.println("Saving the object: " + name);

		hash=name.hashCode();
		subhash=hash%levels;
		pathto=basedir + "/" + subhash + "/" + hash;

		f=new File(basedir + "/" + subhash);
		if(!f.isDirectory()) {
			System.out.println("Making directories for " + f.getPath());
			f.mkdirs();
		}

		try {
			FileOutputStream ostream = new FileOutputStream(pathto);
			ObjectOutputStream p = new ObjectOutputStream(ostream);
			p.writeObject(o);
			p.flush();
			ostream.close();
		} catch(Exception e) {
			System.err.println("Got an exception:  " + e.getMessage());
			throw new RemoteException(e.getMessage());
		}
	}

    public Object getObject(String name) throws RemoteException {
		int hash, subhash;
		String pathto;

		System.out.println("Giving the object '" + name + "' back...");

		hash=name.hashCode();
		subhash=hash%levels;
		pathto=basedir + "/" + subhash + "/" + hash;

		try {
			Object o;
			FileInputStream istream = new FileInputStream(pathto);
			ObjectInputStream p = new ObjectInputStream(istream);
			o = p.readObject();
			return(o);
		} catch(Exception e) {
			System.err.println("Got an exception:  " + e.getMessage());
		}
		return(null);
	}

	public boolean ping() throws RemoteException {
		return(true);
	}
}
