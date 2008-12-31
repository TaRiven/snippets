class
	LDAP

feature {NONE} -- make and data

	ldap_handle: POINTER;

	ldap_host: STRING;

	ldap_port: INTEGER;

	ldap_binddn: STRING;

	ldap_bindpw: STRING;

	ldap_got_entry: BOOLEAN;

feature {ANY} -- Initialization stuff

	set_host(to: STRING) is
		-- Set the server to bind to
		do
			ldap_host:=to;
		end

	set_port(to: INTEGER) is
		-- Set the port to bind to
		do
			ldap_port:=to;
		end

	set_binddn(to: STRING) is
		-- Set the DN to bind as
		do
			ldap_binddn:=to;
		end

	set_bindpw(to: STRING) is
		-- Set the bind password
		do
			ldap_bindpw:=to;
		end

	set_searchbase(to: STRING) is
		-- Set the search base
		do
			c_ldap_set_sb(ldap_handle, to.to_external);
		end

	connect is
		-- Connect to an LDAP server
		local
			host: POINTER;
		do
			if ldap_host /= Void then
				host:=ldap_host.to_external;
			end
			ldap_handle:=c_ldap_init(host, ldap_port);
		ensure
			ldap_handle.is_not_null;
		end

	bind is
		-- Bind to an LDAP server
		local
			binddn, bindpw: POINTER;
		do
			if ldap_binddn /= Void then
				binddn:=ldap_binddn.to_external;
			end
			if ldap_bindpw /= Void then
				bindpw:=ldap_bindpw.to_external;
			end
			check
				c_ldap_bind(ldap_handle, binddn, bindpw);
			end;
		end

	search(filter: STRING; scope: INTEGER) is
		-- Execute a search
		do
			check
				c_ldap_search(ldap_handle, filter.to_external, scope);
			end
		end

	nresults: INTEGER is
		-- Find out how many entries we found
		do
			Result:=c_ldap_nresults(ldap_handle);
		end

	list_attributes: ARRAY[STRING] is
		require
			got_entry;
		local
			s: STRING;
			p: POINTER;
		do
			!!Result.with_capacity(16, 16);
			Result.clear;

			from
				p:=c_ldap_first_attribute(ldap_handle);
			until
				p.is_null
			loop
				!!s.from_external_copy(p);
				Result.add_last(s);
				p:=c_ldap_next_attribute(ldap_handle);
			end
		end

	get_values(att: STRING): ARRAY[STRING] is
		-- Get the values for a given attribute in an existing entry.
		require
			got_entry;
		local
			s: STRING;
			p: POINTER;
			i: INTEGER;
		do
			!!Result.with_capacity(16, 16);
			Result.clear;

			from
				i:=0;
				p:=c_ldap_get_value(ldap_handle, att.to_external, i);
			until
				p.is_null
			loop
				!!s.from_external(p);
				Result.add_last(s);
				i:=i+1;
				p:=c_ldap_get_value(ldap_handle, att.to_external, i);
			end
		end

	first_entry is
		-- Get the first entry
		do
			ldap_got_entry:=c_ldap_first_entry(ldap_handle);
		end

	dispose is
		-- go away
		do
			c_ldap_destroy(ldap_handle);
		end

feature {ANY} -- Status

	got_entry: BOOLEAN is
		do
			Result:=ldap_got_entry;
		end

feature {NONE} -- C functions

	c_ldap_init(host: POINTER; port: INTEGER): POINTER is
		-- The init
		external "C"
		end

	c_ldap_set_sb(ld, search_base: POINTER) is
		-- set the search base
		external "C"
		end

	c_ldap_set_timeout(ld: POINTER; timeout: INTEGER) is
		-- set the search timeout
		external "C"
		end

	c_ldap_bind(ld, binddn, bindpw: POINTER): BOOLEAN is
		-- Bind
		external "C"
		end

	c_ldap_search(ld, filter: POINTER; scope: INTEGER): BOOLEAN is
		-- Search
		external "C"
		end

	c_ldap_destroy(ld: POINTER) is
		-- Free up everything
		external "C"
		end

	c_ldap_nresults(ld: POINTER): INTEGER is
		-- Find out how many results there were from the last search
		external "C"
		end

	c_ldap_first_entry(ld: POINTER): BOOLEAN is
		-- Get the first entry
		external "C"
		end

	c_ldap_first_attribute(ld: POINTER): POINTER is
		-- Get the first entry
		external "C"
		end

	c_ldap_next_attribute(ld: POINTER): POINTER is
		-- Get the first entry
		external "C"
		end

	c_ldap_get_value(ld, attribute: POINTER; index: INTEGER): POINTER is
		-- Get a specific value from an entry
		external "C"
		end

end
