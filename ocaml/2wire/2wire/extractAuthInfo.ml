(*
 * Copyright (c) 2003  Dustin Sallings <dustin@spy.net>
 *
 * arch-tag: 222185e2-7d45-4a8e-b6cb-6422c569c8c3
 *)

open MfgCdb;;

let print_rec m =
	Printf.printf "%s\t%s\t%s\n" m.sn m.id_string
		(Base64.encode_string (Digest.string (m.id_string ^ m.sn)))
;;

let whole_file cdbFile =
	let db = MfgCdb.open_mfg_db cdbFile in
	MfgCdb.iter print_rec db;
	MfgCdb.close_mfg_db db;
;;

let specific_sns cdbFile a =
	let db = MfgCdb.open_mfg_db cdbFile in
	Array.iter (fun sn -> print_rec (MfgCdb.lookup db sn)) a;
	MfgCdb.close_mfg_db db;
;;

let main() =
	let cdbFile = Sys.argv.(1) in
	if ((Array.length Sys.argv) > 2) then (
		specific_sns cdbFile
			(Array.sub Sys.argv 2 ((Array.length Sys.argv) - 2));
	) else (
		whole_file cdbFile
	)
;;

(* Start main if we're interactive. *)
if !Sys.interactive then () else begin main() end;;
