indexing
   description: "Temperature loader."
--
-- Copyright (c) 2002  Dustin Sallings
--
-- $Id: temploader.e,v 1.1 2002/11/23 08:31:39 dustin Exp $
--
class TEMPLOADER

creation {ANY}
   make

feature {ANY}

	make is
		-- Process the tempearture log from stdin
		do

			!!db.make
			db.set_dbname("temperature")
			db.set_username("tempload")
			db.set_password("tempload")
			db.set_host("db")
			db.set_max_retries(0)
			db.connect

			init_sensors
			process_input
		end

feature{NONE}

	db: PG

	serials: DICTIONARY[INTEGER,STRING]

	init_sensors is
		-- Initialize the sensors map
		local
			b: BOOLEAN
			a: ARRAY[STRING]
			ser, id: STRING
		once
			db.query("select sensor_id, serial from sensors")
			!!serials.make
			from
				-- Get the first row
				b := db.get_row
			until
				b = false
			loop
				a := db.last_row

				ser := a @ 1
				id := a @ 0

				-- io.put_string(ser + " = " + id + "%N")

				-- get the ID and the serial and map it
				serials.put(id.to_integer, ser)

				-- Get the next row
				b := db.get_row
			end
		end

	process_input is
		require
			has_db_connection: db /= Void
			has_serial_map: serials /= Void
		local
			line_number: INTEGER
		do
			from
				-- Get the first line
				io.read_line
				line_number := 1
			until
				io.end_of_input
			loop
				-- Process the current line
				process_line(io.last_string, line_number)
				-- Get the next line
				io.read_line
				line_number := line_number + 1
			end
		end

	process_line(line: STRING; line_number: INTEGER) is
		require
			has_line: line /= Void
		local
			done: BOOLEAN
			string_utils: SPY_STRING_UTILS
			a: ARRAY[STRING]
			query: STRING
		do
			-- This allows failures to pass
			if not done then
				done := true

				!!string_utils
				a := string_utils.split_on(io.last_string, '%T')

				-- Print a message
				io.put_string(line_number.to_string
					+ ": " + (a @ 1) + "%T" + (a @ 2) + "=" + (a @ 3) + "%N")

				-- Build the query string
				query := "insert into samples(ts, sensor_id, sample) "
					+ "values('" + (a @ 1) + "', "
					+ (serials @ (a @ 2)).to_string
					+ ", " + (a @ 3) + ")%N"

				-- Perform the insert
				db.query(query)
			end
		rescue
			io.put_string("FAILED:  " + query + db.errmsg + "%N")
			retry
		end

end -- class TEMPLOADER
