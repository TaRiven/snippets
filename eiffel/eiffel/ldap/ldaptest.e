indexing
	author: "Dustin Sallings <dustin@spy.net>";
	copyright: "1997 Dustin Sallings <dustin@spy.net>";
	license: "See forum.txt";
	version: "$Revision: 1.6 $";

class
	LDAPTEST -- Test LDAP program

creation
	make

feature {NONE} -- make and data

	ldap: LDAP;

	do_bind is
		-- Get the password and do the bind.
		require
			ldap /= Void;
		do
			-- ldap.set_binddn("uid=dustin,ou=Agents,dc=spy,dc=net");
			ldap.set_binddn("cn=TheMan,dc=spy,dc=net");
			io.put_string("Enter password:  ");
			io.read_line;
			ldap.set_bindpw(io.last_string);
			ldap.connect;
			ldap.bind;
		end

	do_search is
		-- do the search, display the results.
		require
			ldap.connected;
		local
			a, b: ARRAY[STRING];
			i, j: INTEGER;
		do
			ldap.set_searchbase("dc=spy,dc=net");
			io.put_string("Doing search.%N");
			ldap.search("uid=dustin", 2);
			io.put_string("Search was successful, found ");
			io.put_integer(ldap.nresults);
			io.put_string(" matches.%NAttributes:%N");

			ldap.first_entry;

			from
				a:=ldap.list_attributes;
				i:=a.lower;
			until
				i > a.upper
			loop
				io.put_string("%T" + a @ i + " (");
				b:=ldap.get_values(a @ i);
				io.put_integer(b.count);
				io.put_string(" match(es))%N");
				from
					j:=b.lower;
				until
					j>b.upper
				loop
					io.put_string("%T%T" + b @ j + "%N");
					j:=j+1;
				end
				i:=i+1;
			end
		end

	do_compare is
		-- Do the comparisons
		require
			ldap.connected;
		do
			io.put_string("Doing comparison%N");
			io.put_string("Does dustin have a objectclass=pageservuser?%N");
			if ldap.compare("uid=dustin,ou=Agents,dc=spy,dc=net",
				"objectclass", "pageservuser") then
				io.put_string("Yes%N");
			else
				io.put_string("No%N");
			end
			io.put_string("Doing comparison%N");
			io.put_string("Does sidney have a objectclass=pageservuser?%N");
			if ldap.compare("uid=sidney,ou=Agents,dc=spy,dc=net",
				"objectclass", "pageservuser") then
				io.put_string("Yes%N");
			else
				io.put_string("No%N");
			end
		end

	do_add is
		require
			ldap.connected;
		do
			ldap.add_mod("objectclass", "top");
			ldap.add_mod("objectclass", "pageservuser");
			ldap.add_mod("pageId", "123");
			ldap.add_mod("pageStatId", "456");
			io.put_string("What dn would you like to add?:  ");
			io.read_line;
			ldap.add(io.last_string);
		end

	do_delete is
		require
			ldap.connected;
		do
			io.put_string("What dn would you like to delete?:  ");
			io.read_line;
			ldap.delete(io.last_string);
		end

	make is
		local
			bound: BOOLEAN;
			retries: INTEGER;
		do
			if not bound then
				!!ldap;
				do_bind;
				bound:=true;
				io.put_string("Correct!%N");
			end

			do_search;
			do_compare;
			-- do_add;
			do_delete;

		-- rescue
			-- if not bound then
				-- io.put_string("Incorrect password%N");
			-- else
				-- io.put_string("Search failed%N");
			-- end
			-- if retries < 2 then
				-- retries:=retries+1;
				-- retry;
			-- end
		end

end
