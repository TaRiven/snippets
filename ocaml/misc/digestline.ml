(*
 * Copyright (c) 2003  Dustin Sallings <dustin@spy.net>
 *
 * arch-tag: 6089A459-9C02-11D8-8568-000A957659CC
 *)

(* hex digest of a string *)
let md5 s = Digest.to_hex (Digest.string s)

let main() =
	Fileutils.iter_lines (fun l ->
		print_endline( (md5 l) ^ "," ^ l))
		stdin
;;

(* Start main unless we're interactive. *)
if !Sys.interactive then () else begin main() end
