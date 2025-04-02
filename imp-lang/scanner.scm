;; Author: Isaac H. Lopez Diaz <isaac.lopez@upr.edu>
;; Descrtiption: Scanner for hot lang
(load "helpers.scm")
(load "ehandler.scm")

;; main struct of token
;; 4 tuple: (lexeme, category, row-number, col-number)
(define-structure token lex cat row col)

;; main scanner function
(define scanner
  (lambda (code)
    (scanner-b code 0 0)))

;; helper function for scanner
(define scanner-b
  (lambda (code row col)
    (cond
     ((null? code) '()) ; eof
     ((char=? #\newline (car code)) (scanner-b (cdr code) (+ row 1) 0))
     ((or (char=? #\space (car code))
	  (char=? #\tab (car code)))
      (scanner-b (cdr code) row (+ col 1)))
     ((char=? #\; (car code))
      (cons (make-token ";" 'semi row (+ col 1))
	    (scanner-b (cdr code) row (+ col 1))))
     ((char=? #\< (car code))
      (if (char=? #\= (cadr code))
	  (cons (make-token "<=" 'lteq row (+ col 2))
		(scanner-b (cddr code) row (+ col 2)))
	  (cons (make-token "<" 'lt row (+ col 1))
		(scanner-b (cdr code) row (+ col 1)))))
     ((char=? #\+ (car code))
      (cons (make-token "+" 'plus row (+ col 1))
	    (scanner-b (cdr code) row (+ col 1))))
     ((char=? #\- (car code))
      (cons (make-token "-" 'minus row (+ col 1))
	    (scanner-b (cdr code) row (+ col 1))))
     ((char=? #\* (car code))
      (cons (make-token "*" 'star row (+ col 1))
	    (scanner-b (cdr code) row (+ col 1))))
     ((and (char=? #\: (car code))
	   (char=? #\= (cadr code)))
      (cons (make-token ":=" 'coloneq row (+ col 2))
	    (scanner-b (cddr code) row (+ col 2))))
     ((char=? #\= (car code))
      (cons (make-token "=" 'eq row (+ col 1))
	    (scanner-b (cdr code) row (+ col 1))))
     ((char=? #\~ (car code))
      (cons (make-token "~" 'not row (+ col 1))
	    (scanner-b (cdr code) row (+ col 1))))
     ((and (char=? #\/ (car code))
	   (char=? #\\ (cadr code)))
      (cons (make-token "/\\" 'and row (+ col 2))
	    (scanner-b (cddr code) row (+ col 2))))
     ((and (char=? #\\ (car code))
	   (char=? #\/ (cadr code)))
      (cons (make-token "\\/" 'or row (+ col 2))
	    (scanner-b (cddr code) row (+ col 2))))
     ((char-alphabetic? (car code))
      (let ((word (take-while char-alphabetic? code))
	    (rst (drop-while char-alphabetic? code)))
	(let ((tok (scan-keyword-or-ident word row col)))
	  (cons tok
		(scanner-b rst (token-row tok) (token-col tok))))))
     ((char-numeric? (car code))
      (let ((num (take-while char-numeric? code))
	    (rst (drop-while char-numeric? code)))
	(cons (make-token (list->string num) 'number row (+ col (length num)))
	      (scanner-b rst row (+ col (length num)))))))))

;; helper to scan keyword or identifier
(define scan-keyword-or-ident
  (lambda (word-lst row col)
    (let ((word (list->string word-lst)))
      (cond
       ((string=? word "if")
	(make-token "if" 'if row (+ col 2)))
       ((string=? word "then")
	(make-token "then" 'then row (+ col 4)))
       ((string=? word "else")
	(make-token "else" 'else row (+ col 4)))
       ((string=? word "skip")
	(make-token "skip" 'skip row (+ col 4)))
       ((string=? word "true")
	(make-token "true" 'true row (+ col 4)))
       ((string=? word "false")
	(make-token "false" 'false row (+ col 5)))
       ((string=? word "while")
	(make-token "while" 'while row (+ col 5)))
       ((string=? word "do")
	(make-token "do" 'do row (+ col 2)))
       (else
	(make-token word 'id row (+ col (string-length word))))))))
