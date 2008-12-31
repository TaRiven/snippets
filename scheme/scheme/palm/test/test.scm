; TestTaker source

; Constants
(define testdb "Test")

; Form IDs, etc...
(define edit-frm 1000)
(define question-frm 1001)
(define grade-frm 1002)

(define question-fld 1001)
; Answer fields
(define answer-fld-base 2000)
(define answer-psh-base 3000)
(define answer1-fld 2001)
(define answer1-psh 3001)
(define answer2-fld 2002)
(define answer2-psh 3002)
(define answer3-fld 2003)
(define answer3-psh 3003)
(define answer4-fld 2004)
(define answer4-psh 3004)

(define grade-fld 1000)
; Buttons
(define add-btn 4001)
(define next-btn 4002)
(define grade-btn 4003)
(define ok-btn 4004)

;
; Utility stuff
;

; Vector item swap
(define (vswap v a b)
  (let ( (atmp (vector-ref v a)) (btmp (vector-ref v b) ) )
    (vector-set! v a btmp)(vector-set! v b atmp)))

; shuffle a list
(define (shuffle l)
  ; Convert the input to a vector so we can move stuff around
  (let ( (v (list->vector l)) (s (length l) ) )
    ; Perform one swap operation per list entry
    (do ( (i 0 (+ i 1)))
      ; If we're done, return a list version of our vector
      ( (>= i s) (vector->list v))
      ; Get a random offset in the list
      (let ( (r (random s)))
        ; swap'm
        (vswap v i r)))))

(define (gen-nlist from to)
 (let ( (thelist '()) )
  (do ( (i from (+ i 1)))
   ( (> i to) thelist)
   (set! thelist (append thelist (list i))))))

;
; Database stuff
;

; Get a record
(define (get-record which)
  (map (lambda (x) (hb-getfield testdb which x) ) (gen-nlist 0 6)))

; Find out how many records we have
(define (n-records)
 (car (hb-info testdb)))

; Get the data for the given list of questions
(define (get-test-data questions)
 (map (lambda (x) (get-record x)) questions))

; Get a non-random test
(define (normal-test)
 (get-test-data (gen-nlist 0 (- (n-records) 1))))

; Get a random test
(define (random-test)
 (shuffle (normal-test)))

;
; UI stuff
;

; Populate the textual fields in the current form
(define (populate-fields data)
    (fld-set-text question-fld (list-ref data 0 ))
    (fld-set-text answer1-fld (list-ref data 1 ))
    (fld-set-text answer2-fld (list-ref data 2 ))
    (fld-set-text answer3-fld (list-ref data 3 ))
    (fld-set-text answer4-fld (list-ref data 4 )))

; Clear the answer thingy.

(define (clear-select-buttons)
 (map (lambda (x) (
  ctl-set-val x #f)) (list answer1-psh answer2-psh answer3-psh answer4-psh)))

; Show the correct answer (used in edit forms, etc...)
(define (set-select-button which)
  (clear-select-buttons)
   ; Only do something if it's *not* zero
   (if (zero? which) #f (ctl-set-val (+ answer-psh-base which) #t)))

; Find the ``next item''
(define (next-item current-item wrap)
 (cond
   ( (< current-item (- (n-records) 1)) (+ 1 current-item) )
   (wrap 0)
   (else #f)))

; Display the score
(define (show-score correct questions)
 (frm-popup grade-frm
  (lambda (event . args)
   (case event
    ((frm-open)
	  (fld-set-text grade-fld
	    (string-append "Got " (object->string correct) " out of "
		  (object->string (length questions)) " right")))
	((ctl-select) (frm-return 'graded))
	(else #f)))))

; Grade a test
(define (grade-test questions answers)
 (let ( (correct 0) (total (length questions)) )
  (do ( (i 0 (+ i 1)))
   ( (>= i total) (show-score correct questions))
   (if (= (string->object (list-ref (list-ref questions i) 5))
           (vector-ref answers i))
    (set! correct (+ 1 correct)) #f))))


; Take a test
(define (take-test)
 (set-resdb "TestTaker")
 (let ( (testdata (random-test)) )
  (take-the-test testdata)))

; Show a record, and allow navigation
(define (take-the-test test-data)
  (let ( (current-item 0) (data (list-ref test-data 0))
    (answers (make-vector (length test-data) 0)) )
  (frm-popup question-frm
    (lambda (event . args)
      (case event
        ((menu) (frm-return (list test-data answers)))
        ; When we open the form, populate it with the nth record from the DB
        ((frm-open)
			(set-select-button (vector-ref answers current-item))
            (populate-fields data))
        ; Buttons
        ((ctl-select)
          ; I don't know how to do this with case...
          (cond
            ; Do this if it's the ``next'' button
            ((eqv? (car args) next-btn)
             (set! current-item (next-item current-item #t))
             (set! data (list-ref test-data current-item))
			 (set-select-button (vector-ref answers current-item))
             (populate-fields data))
            ((eqv? (car args) grade-btn)
			 (grade-test test-data answers))
			((eqv? (car args) answer1-psh)
			 (vector-set! answers current-item 1))
			((eqv? (car args) answer2-psh)
			 (vector-set! answers current-item 2))
			((eqv? (car args) answer3-psh)
			 (vector-set! answers current-item 3))
			((eqv? (car args) answer4-psh)
			 (vector-set! answers current-item 4))
            ; Do this for all other buttons
            (else (display "Unknown button:  ")(display args)(newline))))
        (else #f))))))

; Edit the test thingies
(define (edit-test)
  (set-resdb "TestTaker")
  (let ( (testdata (normal-test)) )
    (edit-records (normal-test))))

; Edit a given record
(define (edit-records test-data)
  (let ( (current-item 0) (data (list-ref test-data 0)))
  (frm-popup edit-frm
    (lambda (event . args)
      (case event
        ((menu) (frm-return 'bye))
        ; When we open the form, populate it with the nth record from the DB
        ((frm-open)
            (populate-fields data)
            (set-select-button (string->object (list-ref data 5))))
        ; Buttons
        ((ctl-select)
          ; I don't know how to do this with case...
          (cond
            ; Do this if it's the ``next'' button
            ((eqv? (car args) next-btn)
             (set! current-item (next-item current-item #t))
             (set! data (list-ref test-data current-item))
             (populate-fields data)
             (set-select-button (string->object (list-ref data 5))))
            ; Do this for all other buttons
            (else (display "Unknown button:  ")(display args)(newline))))
        (else #f))))))
