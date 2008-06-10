(*
 * Copyright (c) 2007  Dustin Sallings <dustin@spy.net>
 *)

open Unix

exception UnexpectedResponse of string

exception Timeout

exception OutOfMemory

exception InternalError

exception Draining

exception BadFormat

exception UnknownCommand

exception Buried of int

exception ExpectedCRLF

exception JobTooBig

exception DeadlineSoon

exception NotIgnored

type beanstalk_conn = {
	reader : in_channel;
	writer : out_channel;
}

type beanstalk_job = {
	job_id : int;
	job_data : string;
}

let lookup h =
	let he = gethostbyname h in
	he.h_addr_list.(0)

let connect hostname port =
	let addr = ADDR_INET (lookup hostname, port) in
	let stuff = open_connection addr in
	{ reader = fst stuff; writer = snd stuff }

let shutdown bs =
	shutdown_connection bs.reader

let raise_exception res =
	match (Extstring.split res ' ' 2) with
		  "NOT_FOUND"::_Tl -> raise Not_found
		| "TIMED_OUT"::_Tl -> raise Timeout
		| "OUT_OF_MEMORY"::_Tl -> raise OutOfMemory
		| "INTERNAL_ERROR"::_Tl -> raise InternalError
		| "DRAINING"::_Tl -> raise Draining
		| "BAD_FORMAT"::_Tl -> raise BadFormat
		| "UNKNOWN_COMMAND"::_Tl -> raise UnknownCommand
		| "EXPECTED_CRLF"::_Tl -> raise ExpectedCRLF
		| "JOB_TOO_BIG"::_Tl -> raise JobTooBig
		| "DEADLINE_SOON"::_Tl -> raise DeadlineSoon
		| "NOT_IGNORED"::_Tl -> raise NotIgnored
		| "BURIED"::[id_s] -> raise (Buried (int_of_string id_s))
		| "BURIED"::[] -> raise (Buried 0)
		| _ -> raise (UnexpectedResponse res)

let check_input_line bs expected =
	let res = Extstring.strip_end (input_line bs.reader) in
	if (res = expected) then () else raise_exception res

let use bs name =
	Printf.fprintf bs.writer "use %s\r\n%!" name;
	let expected = Printf.sprintf "USING %s" name in
	check_input_line bs expected

let match_watching bs =
	let res = Extstring.strip_end (input_line bs.reader) in
	match (Extstring.split res ' ' 2) with
		  "WATCHING"::[n] -> int_of_string n
		| _ -> raise_exception res

let watch bs name =
	Printf.fprintf bs.writer "watch %s\r\n%!" name;
	match_watching bs

let ignore bs name =
	Printf.fprintf bs.writer "ignore %s\r\n%!" name;
	match_watching bs

let put bs pri delay ttr data =
	let data_len = String.length data in
	Printf.fprintf bs.writer "put %d %d %d %d\r\n%s\r\n%!"
		pri delay ttr data_len data;
	let res = Extstring.strip_end (input_line bs.reader) in
	match (Extstring.split res ' ' 2) with
		  "INSERTED"::[n] -> int_of_string n
		| _ -> raise_exception res

let read_bytes bs size =
	let buffer = String.create size in
	really_input bs.reader buffer 0 size;
	(* kill crlf *)
	really_input bs.reader (String.create 2) 0 2;
	buffer

let get_job_response bs =
	let res = Extstring.strip_end (input_line bs.reader) in
	match (Extstring.split res ' ' 3) with
		  ["RESERVED"; id; size_str] ->
			let size = int_of_string size_str in
			{job_id = int_of_string id; job_data = read_bytes bs size}
		| ["FOUND"; id; size_str] ->
			let size = int_of_string size_str in
			{job_id = int_of_string id; job_data = read_bytes bs size}
		| _ -> raise_exception res

let sendcmd bs cmd =
	output_string bs.writer (cmd ^ "\r\n");
	flush bs.writer

let reserve bs =
	sendcmd bs "reserve";
	get_job_response bs

let reserve_with_timeout bs timeout =
	Printf.fprintf bs.writer "reserve-with-timeout %d\r\n%!" timeout;
	get_job_response bs

let delete bs id =
	Printf.fprintf bs.writer "delete %d\r\n%!" id;
	check_input_line bs "DELETED"

let release bs id priority delay =
	Printf.fprintf bs.writer "release %d %d %d\r\n%!" id priority delay;
	check_input_line bs "RELEASED"

let parse_tube_list bs =
	let res = Extstring.strip_end (input_line bs.reader) in
	match (Extstring.split res ' ' 2) with
		  "OK"::[size_str] ->
			let size = int_of_string size_str in
			let lines = Extstring.split_chars
				(read_bytes bs size) ['\r'; '\n'] size in
			List.fold_left (fun rv line ->
				match line with
					  "---" -> rv
					| str -> (Extstring.remove_front ['-'; ' '] str)::rv
				) [] lines
		| _ -> raise_exception res

let list_tubes bs =
	sendcmd bs "list-tubes";
	parse_tube_list bs

let list_tubes_watched bs =
	sendcmd bs "list-tubes-watched";
	parse_tube_list bs

let used_tube bs =
	sendcmd bs "list-tube-used";
	let res = Extstring.strip_end (input_line bs.reader) in
	match (Extstring.split res ' ' 2) with
		  "USING"::[name] -> name
		| _ -> raise_exception res

let bury bs id pri =
	Printf.fprintf bs.writer "bury %d %d\r\n%!" id pri;
	check_input_line bs "BURIED"

let kick bs bound =
	Printf.fprintf bs.writer "kick %d\r\n%!" bound;
	let res = Extstring.strip_end (input_line bs.reader) in
	match (Extstring.split res ' ' 2) with
		  "KICKED"::[count_s] -> int_of_string count_s
		| _ -> raise_exception res

let peek bs id =
	Printf.fprintf bs.writer "peek %d\r\n%!" id;
	get_job_response bs

let peek_ready bs =
	sendcmd bs "peek-ready";
	get_job_response bs

let peek_buried bs =
	sendcmd bs "peek-buried";
	get_job_response bs
