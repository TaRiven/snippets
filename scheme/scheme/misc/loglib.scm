; Copyright (c) 2002  Dustin Sallings <dustin@spy.net>
;
; $Id: loglib.scm,v 1.2 2002/12/28 11:47:18 dustin Exp $

(module loglib
	  (import
		(stringlib "../stringlib.scm")
		(dates "../dates.scm"))
		(export
		  parse-2wire-date
		  parse-2wire-date-withmillis
		  approx-time))

; Parse the date out of the given line
(define (parse-2wire-date line)
  (+ (apply dates-seconds-for-time
		 (map string->integer
			  (string-split-chars
				(substring line 0 19)
				'(#\: #\space #\-)
				19)))
	 28800))

; Parse the date out of the given line (including milliseconds)
(define (parse-2wire-date-withmillis line)
  (+ (parse-2wire-date line)
	(/ (string->real (substring line 20 23)) 1000.0)))

; Truncate a date to the nearest minute
(define (approx-time x)
  (* 60 (truncate (/ x 60))))
