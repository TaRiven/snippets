(*
 * Copyright (c) 2004  Dustin Sallings <dustin@spy.net>
 *
 * arch-tag: 653777-35-4115-9419-5333
 *)

(* Column type *)
type 'a col_t = {
	name: string;
	avg: ('a list -> 'a);
};;

(* Get the sum of a list of numbers *)
let sum l = List.fold_left (+.) 0.0 l ;;

(* Get the average of the numbers in a list *)
let simpleAvg l = (sum l) /. float_of_int(List.length l) ;;

(* Get the average of the numbers in a list minus the highest and lowest *)
let avg l =
	(* Sort the list *)
	let sl = List.sort compare l in
	(* Remove the first and last elements *)
	let tl = List.tl (List.rev (List.tl (List.rev sl))) in
	simpleAvg tl
;;

(* Make columns *)
let columnMaker avgfun louter linner =
	List.concat (List.map (fun t ->
		List.map (fun subt ->
			let cname = t ^ subt in
			{	name = cname;
				avg = avgfun t subt;
			})
			linner)
		louter)
;;
