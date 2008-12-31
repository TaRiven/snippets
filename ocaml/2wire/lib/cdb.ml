(*
 * Copyright (c) 2003  Dustin Sallings <dustin@spy.net>
 *
 * arch-tag: 1E3B7401-2AE1-11D8-A379-000393CB0F1E
 *)

(** CDB Implementation.
 {{:http://cr.yp.to/cdb/cdb.txt} http://cr.yp.to/cdb/cdb.txt}
 *)

(* The cdb hash function is ``h = ((h << 5) + h) ^ c'', with a starting
   hash of 5381.
 *)

(** CDB creation handle. *)
type cdb_creator = {
	table_count: int array;
	mutable pointers: (int * int) list;
	out: out_channel;
};;

(** Initial hash value *)
let hash_init = 5381;;

(** Hash the given string. *)
let hash s =
	let h = ref hash_init in
	String.iter (fun c -> h := ((!h lsl 5) + !h) lxor (int_of_char c)) s;
	!h
;;

(** Write a little endian integer to the file *)
let write_le cdc i =
	output_byte cdc.out (i land 0xff);
	output_byte cdc.out ((i lsr 8) land 0xff);
	output_byte cdc.out ((i lsr 16) land 0xff);
	output_byte cdc.out ((i lsr 24) land 0xff)
;;

(**
	Open a cdb creator for writing.

	@param fn the file to write
 *)
let open_out fn =
	let s = {	table_count=Array.make 256 0;
				pointers=[];
				out=open_out_bin fn
			} in
	(* Skip over the header *)
	seek_out s.out 2048;
	s
;;

(** Add a value to the cdb *)
let add cdc k v =
	(* Add the hash to the list *)
	let h = hash k in
	cdc.pointers <- cdc.pointers @ [(h, pos_out cdc.out)];
	cdc.table_count.(h land 0xff) <- cdc.table_count.(h land 0xff) + 1;

	(* Add the data to the file *)
	write_le cdc (String.length k);
	write_le cdc (String.length v);
	output_string cdc.out k;
	output_string cdc.out v;

;;

(** Is this option none? *)
let is_none = function
	None -> true
	| _ -> false
;;

(** Is this option some? *)
let is_some = function
	Some(x) -> true
	| _ -> false
;;

exception Empty_option;;

(** Get an option value  *)
let get_option o = function
	Some(x) -> x
	| None -> raise Empty_option
;;

(** Process a hash table *)
let process_table cdc table_start slot_table slot_pointers i tc =
	(* Length of the table *)
	let len = tc * 2 in
	(* Store the table position *)
	slot_table := !slot_table @ [(pos_out cdc.out, len)];
	(* Build the hash table *)
	let ht = Array.make len None in
	let cur_p = ref table_start.(i) in
	(* from 0 to tc-1 because the loop will run an extra time otherwise *)
	for u = 0 to (tc - 1) do
		let hp = slot_pointers.(!cur_p) in
		cur_p := !cur_p + 1;

		(* Find an available hash bucket *)
		let rec find_where where =
			if (is_none ht.(where)) then
				where
			else (
				if ((where + 1) = len) then (find_where 0)
				else (find_where (where + 1))
			) in
		(* Do an lsr 8 to divide by 256 without breaking negs *)
		let where = find_where (((fst hp) lsr 8) mod len) in
		ht.(where) <- Some hp;
	done;
	(* Write this hash table *)
	Array.iter (fun hpp ->
		match hpp with
		  None ->
			write_le cdc 0;
			write_le cdc 0;
		| Some(hp) ->
			write_le cdc (fst hp);
			write_le cdc (snd hp)
		) ht;
;;

(** Close and finish the cdb creator. *)
let close_cdb_out cdc =
	let cur_entry = ref 0 in
	let table_start = Array.make 256 0 in
	(* Find all the hash starts *)
	Array.iteri (fun i x ->
		cur_entry := !cur_entry + x;
		table_start.(i) <- !cur_entry) cdc.table_count;
	(* Build out the slot pointers array *)
	let slot_pointers = Array.make (List.length cdc.pointers) (0,0) in
	(* Fill in the slot pointers *)
	List.iter (fun hp ->
		let h = fst hp in
		table_start.(h land 0xff) <- table_start.(h land 0xff) - 1;
		slot_pointers.(table_start.(h land 0xff)) <- hp
		) cdc.pointers;
	(* Write the shit out *)
	let slot_table = ref [] in
	(* Write out the hash tables *)
	Array.iteri (process_table cdc table_start slot_table slot_pointers)
		cdc.table_count;
	(* write out the pointer sets *)
	seek_out cdc.out 0;
	List.iter (fun x -> write_le cdc (fst x); write_le cdc (snd x))
		!slot_table;
	close_out cdc.out
;;

(** {1 Iterating a cdb file} *)

(* read a little-endian integer *)
let read_le f =
	let a = (input_byte f) in
	let b = (input_byte f) in
	let c = (input_byte f) in
	let d = (input_byte f) in
	a lor (b lsl 8) lor (c lsl 16) lor (d lsl 24)
;;

(**
 Iterate a CDB.

 @param f the function to call for every key/value pair
 @param fn the name of the cdb to iterate
 *)
let iter f fn =
	let fin = open_in_bin fn in
	try
		(* Figure out where the end of all data is *)
		let eod = read_le fin in
		(* Seek to the record section *)
		seek_in fin 2048;
		let rec loop() =
			if ((pos_in fin) < eod) then (
				let klen = read_le fin in
				let dlen = read_le fin in
				let key = String.create klen in
				let data = String.create dlen in
				really_input fin key 0 klen;
				really_input fin data 0 dlen;
				f key data;
				loop()
			) in
		loop();
		close_in fin;
	with x -> close_in fin; raise x;
;;

(** {1 Searching } *)

(** Type type of a cdb_file. *)
type cdb_file = {
	f: in_channel;
	(* Position * length *)
	tables: (int * int) array;
};;

(** Open a CDB file for searching.

 @param fn the file to open
 *)
let open_cdb_in fn =
	let fin = open_in_bin fn in
	let tables = Array.make 256 (0,0) in
	(* Set the positions and lengths *)
	Array.iteri (fun i it ->
		let pos = read_le fin in
		let len = read_le fin in
		tables.(i) <- (pos,len);
		(*
		print_endline("Table " ^ (string_of_int i) ^ " is "
			^ (string_of_int (fst tables.(i))) ^ ", "
			^ (string_of_int (snd tables.(i))));
		*)
		) tables;
	{f=fin; tables=tables}
;;

(**
 Close a cdb file.

 @param cdf the cdb file to close
 *)
let close_cdb_in cdf =
	close_in cdf.f
;;

(** Get a stream of matches.

 @param cdf the cdb file
 @param key the key to search
 *)
let get_matches cdf key =
	let kh = hash key in
	(* Find out where the hash table is *)
	let hpos, hlen = cdf.tables.(kh land 0xff) in
	(* Go to the hash and figure out where this slot is *)
	let slot_num = ((kh lsr 8) mod hlen) in
	let myiter = ref 0 in
	let incr_slot x = (if (1 + x) > hlen then 0 else (1 + x)) in
	let rec loop x =
		let lslot = (slot_num + !myiter) mod hlen in
		myiter := !myiter + 1;
		if(x >= hlen) then (
			None
		) else (
			let spos = (lslot * 8) + hpos in
			seek_in cdf.f spos;
			let h = read_le cdf.f in
			let pos = read_le cdf.f in
			(* validate that we a real bucket *)
			if (h = kh) && (pos > 0) then (
				seek_in cdf.f pos;
				let klen = read_le cdf.f in
				if (klen = String.length key) then (
					let dlen = read_le cdf.f in
					let rkey = String.create klen in
					really_input cdf.f rkey 0 klen;
					if(rkey = key) then (
						let rdata = String.create dlen in
						really_input cdf.f rdata 0 dlen;
						Some(rdata)
					) else (
						loop (x + 1)
					)
				) else (
					loop (x + 1)
				)
			) else (
				loop (x + 1)
			)
		) in
	Stream.from loop
;;

(**
 Find the first record with the given key.

 @param cdf the cdb_file
 @param key the key to find
 *)
let find cdf key =
	Stream.next (get_matches cdf key)
;;

(** test app to create ``test.cdb'' and put some stuff in it *)
let main() =
	let c = open_out "test.cdb" in
	add c "a" "1";
	add c "b" "2";
	add c "c" "3";
	add c "c" "4";
	add c "dustin" "We're number one!";
	close_cdb_out c;
	iter (fun k v -> print_endline(k ^ " -> " ^ v)) "test.cdb";
	print_endline("*** Searching a ***");
	let cdf = open_cdb_in "test.cdb" in
	print_endline(find cdf "a");
	print_endline("*** Searching c ***");
	print_endline(find cdf "c");
	print_endline("*** Stream searching c ***");
	let str = get_matches cdf "c" in
	let str2 = get_matches cdf "c" in
	print_endline(Stream.next str);
	print_endline(Stream.next str2);
	print_endline(Stream.next str);
	print_endline(Stream.next str2);
	(
	try
		print_endline("Testing stream exhaustion failure");
		print_endline(Stream.next str);
		print_endline("!!! Expected failure.");
	with Stream.Failure -> print_endline("failed as expected")
	);
	print_endline("*** Stream.iter ***");
	Stream.iter print_endline (get_matches cdf "c");
	close_cdb_in cdf;
;;

(* Start main if we're interactive. *)
if !Sys.interactive then () else begin main() end;;
