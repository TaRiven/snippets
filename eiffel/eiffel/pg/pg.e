indexing
   description: "Postgres database access...";
version: "$Revision: 1.20 $";
author: "Dustin Sallings <dustin@spy.net>";
copyright: "1999";
license: "See forum.txt.";
--
-- Copyright (c) 1999  Dustin Sallings
--
-- $Id: pg.e,v 1.20 1999/06/03 22:25:34 dustin Exp $
--
class PG

inherit
   MEMORY
      redefine dispose
      end;

creation {ANY}
   make

feature {PG} -- Creation is private

   make is
      -- Make an uninitialized PG object.
      do
         current_row := 0;
         !!last_row.make(0,16);
         last_row.clear;
         conn := nullpointer;
      end -- make

feature {ANY} -- Connection options

   set_host(to: STRING) is
      -- Set database host to connect to
      do
         !!host.copy(to);
      end -- set_host

   set_port(to: STRING) is
      -- Set database port to connect to
      do
         !!port.copy(to);
      end -- set_port

   set_options(to: STRING) is
      -- Set database connection options
      do
         !!options.copy(to);
      end -- set_options

   set_tty(to: STRING) is
      -- Set database tty
      do
         !!tty.copy(to);
      end -- set_tty

   set_dbname(to: STRING) is
      -- Set database to connect to
      do
         !!dbname.copy(to);
      end -- set_dbname

   set_username(to: STRING) is
      -- Set username to connect as
      do
         !!username.copy(to);
      end -- set_username

   set_password(to: STRING) is
      -- Set password for authentication
      do
         !!password.copy(to);
      end -- set_password

   connect is
      -- Make a database connection
      local
         h, p, o, t, d, u, pass: POINTER;
         retry_attempts: INTEGER;
      do
         if is_not_connected then
            if host /= Void then
               h := host.to_external;
            end;
            if port /= Void then
               p := port.to_external;
            end;
            if options /= Void then
               o := options.to_external;
            end;
            if tty /= Void then
               t := tty.to_external;
            end;
            if dbname /= Void then
               d := dbname.to_external;
            end;
            if username /= Void then
               u := username.to_external;
            end;
            if password /= Void then
               pass := password.to_external;
            end;
            conn := pg_connect(h,p,o,t,d,u,pass);
            check
               pg_connection_ok(conn);
            end;
         end;
      ensure
         is_connected;
      rescue
         if retry_attempts < max_retry_attempts then
            retry_attempts := retry_attempts + 1;
            retry;
         end;
      end -- connect

feature {ANY} -- Query features

   query(q: STRING) is
      -- Query on an open database connection
      require
         is_connected;
      local
         retry_attempts: INTEGER;
      do
         current_row := 0;
         debug
            io.put_string("PG: Doing query:  ");
            io.put_string(q);
            io.put_string("%N-------------------------%N");
         end;
         res := pg_query(conn,q.to_external);
      ensure
         query_successful;
      rescue
         if retry_attempts < max_retry_attempts then
            retry_attempts := retry_attempts + 1;
            retry;
         end;
      end -- query

   num_rows: INTEGER is
      -- Number of rows returned from the last query
      require
         has_results;
      do
         Result := pg_ntuples(res);
      end -- num_rows

   get_row: BOOLEAN is
      -- Get the next row of data back, returns false if there's no more data
      require
         has_results;
      local
         i, fields: INTEGER;
         s: STRING;
         p: POINTER;
      do
         if current_row >= num_rows then
            pg_clear_result(res);
            res := nullpointer;
            Result := false;
         else
            from
               fields := pg_nfields(res);
               last_row.clear;
               i := 0;
            until
               i >= fields
            loop
               p := pg_intersect(res,current_row,i);
               !!s.from_external_copy(p);
               last_row.add_last(s);
               i := i + 1;
            end;
            current_row := current_row + 1;
            Result := true;
         end;
      end -- get_row

feature {ANY} -- Transaction

   begin is
      require
         is_connected;
      do
         query("begin transaction");
      end -- begin

   commit is
      require
         is_connected;
      do
         query("commit");
      end -- commit

   rollback is
      require
         is_connected;
      do
         query("rollback");
      end -- rollback

feature {ANY} -- Utility

   quote(s: STRING): STRING is
      -- Quote a string for safety.
      require
         s /= Void;
      local
         tmp: STRING;
         i: INTEGER;
      do
         !!tmp.copy("'");
         if s.index_of('%'') < s.count then
            -- We only need to do this slow copy if we've got a quote
            from
               i := 0;
            until
               i > tmp.count
            loop
               if s.item(i) = '%'' then
                  tmp.append_character('%'');
               end;
               tmp.append_character(s.item(i));
               i := i + 1;
            end;
         else
            tmp.append(s);
         end;
         tmp.append("'");
         Result := tmp;
      end -- quote

feature {ANY} -- Database Information

   tables: ARRAY[STRING] is
      -- List all tables in this database.
      require
         is_connected;
      local
         a: ARRAY[STRING];
         b: BOOLEAN;
         q: STRING;
      do
         !!Result.with_capacity(0,16);
         Result.clear;
         q := "select tablename from pg_tables " + "where tablename not like 'pg_%%'";
         query(q);
         from
            b := get_row;
         until
            b = false
         loop
            a := last_row;
            Result.add_last(a @ 0);
            b := get_row;
         end;
      ensure
         Result /= Void;
      end -- tables

   sequences: ARRAY[STRING] is
      -- List all sequences in this database.
      require
         is_connected;
      local
         a: ARRAY[STRING];
         b: BOOLEAN;
         q: STRING;
      do
         !!Result.with_capacity(0,16);
         Result.clear;
         !!q.copy("select * from pg_class where relkind='S'");
         query(q);
         from
            b := get_row;
         until
            b = false
         loop
            a := last_row;
            Result.add_last(a @ 0);
            b := get_row;
         end;
      ensure
         Result /= Void;
      end -- sequences

feature {ANY} -- status

   is_connected: BOOLEAN is
      -- Find out if we're connected.
      do
         Result := conn.is_not_null;
      end -- is_connected

   is_not_connected: BOOLEAN is
      -- Find out if we're not connected (shortcut)
      do
         Result := not is_connected;
      end -- is_not_connected

   has_results: BOOLEAN is
      -- Find out if we have results
      do
         Result := res.is_not_null;
      end -- has_results

   query_successful: BOOLEAN is
      -- Find out if the query was successful
      require
         has_results;
      do
         Result := pg_command_ok(res) or pg_tuples_ok(res);
      end -- query_successful

feature {ANY} -- Available data

   current_row: INTEGER;
      -- Current row number we're on.

   last_row: ARRAY[STRING];
      -- Last row retrieved.

feature {PG} -- Internal data stuff

   max_retry_attempts: INTEGER is 3;
      -- number of times to retry on exception

   conn: POINTER;
      -- Connection holder for C library.

   res: POINTER;
      -- Result holder for C library.

   nullpointer: POINTER;
      -- Result holder for C library.

   host: STRING;
      -- Database host

   port: STRING;
      -- Database port

   options: STRING;
      -- Database options

   tty: STRING;
      -- Database tty

   dbname: STRING;
      -- Database name

   username: STRING;
      -- Database username

   password: STRING;
      -- Database password

feature {PG} -- Destructor

   dispose is
      do
         if conn /= Void then
            debug
               io.put_string("PG: Closing database connection.%N");
            end;
            pg_finish(conn);
            conn := nullpointer;
         end;
      end -- dispose

feature {PG} -- Constants from pq

   pg_connection_ok(c: POINTER): BOOLEAN is
      external "C_WithoutCurrent"
      end -- pg_connection_ok

   pg_connection_bad(c: POINTER): BOOLEAN is
      external "C_WithoutCurrent"
      end -- pg_connection_bad

   pg_empty_query(r: POINTER): BOOLEAN is
      external "C_WithoutCurrent"
      end -- pg_empty_query

   pg_command_ok(r: POINTER): BOOLEAN is
      external "C_WithoutCurrent"
      end -- pg_command_ok

   pg_tuples_ok(r: POINTER): BOOLEAN is
      external "C_WithoutCurrent"
      end -- pg_tuples_ok

   pg_copy_out(r: POINTER): BOOLEAN is
      external "C_WithoutCurrent"
      end -- pg_copy_out

   pg_copy_in(r: POINTER): BOOLEAN is
      external "C_WithoutCurrent"
      end -- pg_copy_in

   pg_bad_response(r: POINTER): BOOLEAN is
      external "C_WithoutCurrent"
      end -- pg_bad_response

   pg_nonfatal_error(r: POINTER): BOOLEAN is
      external "C_WithoutCurrent"
      end -- pg_nonfatal_error

   pg_fatal_error(r: POINTER): BOOLEAN is
      external "C_WithoutCurrent"
      end -- pg_fatal_error

feature {PG} -- C bindings

   pg_result_status(r: POINTER): INTEGER is
      external "C_WithoutCurrent"
      alias "PQresultStatus"
      end -- pg_result_status

   pg_result_status_string(of: INTEGER): POINTER is
      external "C_WithoutCurrent"
      alias "PQresStatus"
      end -- pg_result_status_string

   pg_connect(h, p, o, t, d, u, pass: POINTER): POINTER is
      external "C_WithoutCurrent"
      alias "PQsetdbLogin"
      end -- pg_connect

   pg_query(c, q: POINTER): POINTER is
      external "C_WithoutCurrent"
      alias "PQexec"
      end -- pg_query

   pg_intersect(r: POINTER; i, j: INTEGER): POINTER is
      external "C_WithoutCurrent"
      alias "PQgetvalue"
      end -- pg_intersect

   pg_ntuples(r: POINTER): INTEGER is
      external "C_WithoutCurrent"
      alias "PQntuples"
      end -- pg_ntuples

   pg_nfields(r: POINTER): INTEGER is
      external "C_WithoutCurrent"
      alias "PQnfields"
      end -- pg_nfields

   pg_clear_result(r: POINTER) is
      external "C_WithoutCurrent"
      alias "PQclear"
      end -- pg_clear_result

   pg_finish(r: POINTER) is
      external "C_WithoutCurrent"
      alias "PQfinish"
      end -- pg_finish

end -- class PG
