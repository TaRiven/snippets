// Copyright (c) 2000  Dustin Sallings <dustin@spy.net>
//
// $Id: ConsultantHome.java,v 1.1 2000/01/22 09:45:18 dustin Exp $

package net.spy.consult;

import javax.ejb.*;
import java.rmi.RemoteException;
import java.util.Enumeration;

public interface ConsultantHome extends EJBHome {
	public Consultant create(int id, String fn, String ln)
		throws RemoteException, CreateException;
	public Consultant findByPrimaryKey(ConsultantPK pk)
		throws RemoteException, FinderException;
	public Enumeration findByLastName(String ln)
		throws RemoteException, FinderException;
	public Enumeration findByFirstName(String fn)
		throws RemoteException, FinderException;
}
