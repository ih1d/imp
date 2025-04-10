;; Author: Isaac H. Lopez Diaz <isaac.lopez@upr.edu>
;; Description: Weakest precondition eval
;; Licensed under MIT
(load "helpers.scm")

(define-syntax skip
  (syntax-rules ()
    ((_ R)
     R)))

(define-syntax abort
  (syntax-rules ()
    ((_) #f)
    ((_ x ...) #f)))

(define-syntax var
  (syntax-rules ()
    ((_ x y)
     (define x y))))

(define-syntax :=
  (syntax-rules ()
    ((_ x y)
     (set! x y))))

(define-syntax seq
  (syntax-rules ()
    ((_ x ...)
     (begin
       x
       ...))))

(define-syntax when
  (syntax-rules (then else)
    ((_ pred (then then-expr) (else else-expr))
     (if pred
	 then-expr
	 else-expr))))

(define-syntax while
  (syntax-rules ()
    ((_ pred b1 ...)
     (let loop ()
       (if pred
	   (begin
	     b1 ...
	     (loop)))))))

(define-syntax true
  (syntax-rules ()
    ((_) #t)))

(define-syntax false
  (syntax-rules ()
    ((_) #f)))

;; Evaluates the weakest precondition P
;; for statement S and postcondition R
(define wp
  (lambda (S R env)
    (cond
     ((null? S) '())
     ((eq? (car S) 'skip)
      (reduce R))
     ((eq? (car S) 'abort)
      (false))
     ((or (eq? (car S) 'var)
	  (eq? (car S) ':=))
      (let ((v (lookup (second S) R)))
	(if v
	    (reduce (substitute v (third S) R))
	    (error (second S) "variable does not exist."))))
     ((eq? (car S) 'seq)
      (wp (cadr S) (wp (caddr S) R)))
     ((eq? (car S) 'when)
      (let ((c (cadr S))
	    (t (wp (cadr (caddr S)) R))
	    (e (wp (cdr (cadddr S)) R)))
	(and (eval (implies c t) user-initial-environment)
	     (eval (implies (not c) e)) user-initial-environment)))
     (else
      (error (car S) "not defined")))))

;; Lookup for a variable v in R
(define lookup
  (lambda (v R)
    (cond
     ((null? R) #f)
     ((eq? v (car R)) v)
     (else
      (lookup v (cdr R))))))

;; Substitute variable v for expression e in R
(define substitute
  (lambda (v e R)
    (cond
     ((null? R) '())
     ((eq? v (car R))
      (append (cdr R)
	    (list e)))
     (else
      (cons (car R)
	    (substitute v e (cdr R)))))))

;; Reverse an operator
(define rev
  (lambda (op)
    (cond
     ((eq? op '+) -)
     ((eq? op '-) +)
     ((eq? op '/) *)
     ((eq? op '*) /)
     (else
      (error op "not defined")))))

;; Reduce an expression (simplification)
(define reduce
  (lambda (expr)
    (if (null? expr)
	(error expr "is empty")
	(let ((rel (car expr))
	      (lhs (cadr expr))
	      (rhs (caddr expr)))
	  (cond	   
	   ((list? lhs)
	    (let ((op (car lhs))
		  (nlhs (cadr lhs))
		  (nrhs (caddr lhs)))
	      (if (symbol? nlhs)
		  `(,rel ,nlhs ,(apply (rev op) (list rhs nrhs)))
		  `(,rel ,(apply (rev op) (list rhs nlhs)) ,nrhs))))
	   ((list? rhs)
	    (let ((op (car rhs))
		  (nlhs (cadr rhs))
		  (nrhs (caddr rhs)))
	      (if (symbol? nrhs)
		  `(,rel ,(apply (rev op) (list lhs nlhs)) ,nrhs)
		  `(,rel ,nlhs ,(apply (rev op) (list lhs nrhs))))))
	   ((symbol? lhs)
	    `(,rel ,lhs ,rhs))
	   (else (eval expr user-initial-environment)))))))
