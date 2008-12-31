/*
 * Copyright (c) 1999 Dustin Sallings <dustin@spy.net>
 *
 * $Id: openldap_stuff.h,v 1.6 1999/06/07 19:50:37 dustin Exp $
 * See forum.txt for licensing information.
 */

#ifdef OPENLDAP

#include <lber.h>
#include <ldap.h>

typedef struct {

	char   *ldap_host;
	int     ldap_port;

	char   *search_base;
	char   *query_filter;
	char   *result_attribute;

	int     bind;
	char   *binddn;
	char   *bindpw;

	int     timeout;

	char  **attr_values;
	char   *value_tmp;

	LDAP   *ld;

	int     last_error;

	LDAPMessage *res;
	LDAPMessage *entry;

	LDAPMod **mods;

	BerElement *ber;

} LDAP_HANDLE;

#endif /* OPENLDAP */
