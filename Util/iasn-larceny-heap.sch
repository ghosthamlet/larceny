; Copyright 1998-2004 Lars T Hansen.    -*- mode: scheme; mode: font-lock -*-
;
; $Id: larceny-heap.sch 2916 2006-04-27 21:25:00Z tov $
;
; IAssassin Larceny:
; Script for building the full heap image "larceny.heap"
;
; 1  Evaluate (BUILD-LARCENY-FILES) in the development environment
; 2  From the command line run
;        larceny.bin -stopcopy sasstrap.heap
; 3  Load this script.  It will create larceny.heap.
;
; BUGS:
; - The FFI and record package internals are not hidden.
; - Some files that are no longer in Auxlib and Experimental (they
;   have been moved to an external library) are not loaded

(define ($$trace x) #f)                 ; Some code uses this

(define toplevel-macro-expand #f)       ; A hack for the benefit of 
                                        ; init-toplevel-environment

(define (displn x) (display x) (newline))

;;; First load the compiler and seal its namespace.

(let ()
    
  (define basedir "")
  (define verbose #t)

  (define (file-newer? f1 f2)
    (let ((t1 (file-modification-time f1))
	  (t2 (file-modification-time f2)))
      (let loop ((i 0))
	(cond ((= i (vector-length t1)) #f)
	      ((= (vector-ref t1 i) (vector-ref t2 i))
	       (loop (+ i 1)))
	      (else
	       (> (vector-ref t1 i) (vector-ref t2 i)))))))

  (define (rewrite-file-type fn)
    (let* ((j   (string-length fn))
	   (ext ".sch")
	   (new ".fasl")
	   (l   (string-length ext)))
      (if (file-type=? fn ext)
	  (string-append (substring fn 0 (- j l)) new)
	  fn)))

  (define (file-type=? file-name type-name)
    (let ((fl (string-length file-name))
	  (tl (string-length type-name)))
      (and (>= fl tl)
	   (string-ci=? type-name
			(substring file-name (- fl tl) fl)))))

  (define (prefer-fasl fn)
    (let ((fasl (rewrite-file-type fn)))
      (if (or (and (not (file-exists? fn))
		   (file-exists? fasl))
	      (and (file-exists? fn)
		   (file-exists? fasl)
		   (file-newer? fasl fn)))
	  fasl
	  fn)))

  (define (loadf files)
    (for-each (lambda (fn)
		(let ((fn (prefer-fasl (string-append basedir fn))))
		  (if verbose
		      (begin (display fn)
			     (newline)))
		  (load fn)))
	      files))

  (load "Util/petit-setup.sch")
  (setup 'sassy)
  (load-compiler 'release)
  (load "Asm/Common/link-lop.fasl")

  (let ((interaction-environment interaction-environment)
        (compile-expression compile-expression)
        (link-lop-segment link-lop-segment)
        (evaluator evaluator)
        (macro-expand-expression macro-expand-expression))

    (define twobit
      (let ((old-evaluator (evaluator)))
        (lambda (expr . rest)
          '(begin (display `(twobiting ,expr)) (newline))
          (let* ((env (if (null? rest)
                         (interaction-environment)
                         (car rest)))
                 (compiled (parameterize ((evaluator old-evaluator))
                             (compile-expression expr env)))
                 (linked   (link-lop-segment compiled env)))
            (linked)))))

    (evaluator twobit))

  (displn "Install twobit's macro expander as the interpreter's ditto")

  (macro-expander (lambda (form environment)
		    (let ((switches (compiler-switches 'get)))
		      (dynamic-wind
			  (lambda ()
			    (compiler-switches 'standard))
			  (lambda ()
			    (twobit-expand form (environment-syntax-environment environment)))
			  (lambda ()
			    (compiler-switches 'set! switches))))))
  ; Kids, don't try this at home
  (vector-like-set! (interaction-environment) 
		    4
		    (the-usual-syntactic-environment))

  (displn "Replace and populate the top-level environment")

  (displn "Lib/Common/toplevel.fasl")
  (load "Lib/Common/toplevel.fasl")
  (displn "Lib/IAssassin/toplevel-target.fasl")
  (load "Lib/IAssassin/toplevel-target.fasl")

  (displn "done with load")

  (let ((e (interaction-environment)))
    (letrec ((install-procedures 
              (lambda (x procs)
                (if (not (null? procs))
                    (begin
                      (environment-set! x
                                        (car procs)
                                        (environment-get e (car procs)))
                      (install-procedures x (cdr procs)))))))
        
  
      ; Replace the existing environments with fresh environments
      ; containing the bindings for the standard names; those bindings are 
      ; initialized with values taken from the current interaction
      ; environment.
      (init-toplevel-environment)
      
      (install-procedures (interaction-environment)
                          '(; Compilation
                            compile-file
                            assemble-file
                            compile-expression
                            macro-expand-expression
                            ; On-line help
                            help
                            ; Disassembler
                            ;; FSK: not on IAssassin
                            ;; disassemble-codevector
                            ;; print-instructions
                            ;; disassemble-file
                            ;; disassemble
                            ; Compiler and assembler switches
                            compiler-switches
                            compiler-flags
                            global-optimization-flags
                            runtime-safety-flags
                            issue-warnings
                            include-procedure-names
                            include-source-code
                            include-variable-names
                            single-stepping
                            avoid-space-leaks
                            ;; FSK: not on IAssassin
                            ;; write-barrier
                            runtime-safety-checking
                            catch-undefined-globals
                            integrate-procedures
                            control-optimization
                            parallel-assignment-optimization
                            lambda-optimization
                            benchmark-mode
                            benchmark-block-mode
                            global-optimization
                            interprocedural-inlining
                            interprocedural-constant-propagation
                            common-subexpression-elimination
                            representation-inference
                            local-optimization
                            peephole-optimization
                            inline-allocation
                            ;; FSK: not on IAssassin
                            ;; fill-delay-slots
                            ; Make utility
                            make:project
                            make:new-project
                            make:project?
                            make:rule
                            make:deps
                            make:targets
                            make:pretend
                            make:debug
                            make:make))))


  (unspecified))

"Redefine MACRO-EXPAND in the interaction environment."

(define macro-expand
  (lambda (expr . rest)
    (let ((env (if (null? rest)
                   (interaction-environment)
                   (car rest))))
      (macro-expand-expression expr env))))

"Helpful procedure for hiding irrelevant names"

(define (load-in-private-namespace files procs)
  (let ((e (environment-copy (interaction-environment))))
    (for-each (lambda (f) (load f e)) files)
    (let ((x (interaction-environment)))
      (do ((procs procs (cdr procs)))
          ((null? procs))
        (environment-set! x
                          (car procs)
                          (environment-get e (car procs)))))))

"Load a bunch of useful procedures"

(load-in-private-namespace
 '("Auxlib/pp.fasl"
   "Auxlib/misc.fasl"
   "Auxlib/list.fasl"
   "Auxlib/string.fasl"
   "Auxlib/vector.fasl"
   "Auxlib/pp.fasl"
   "Auxlib/io.fasl"
   "Auxlib/osdep-unix.fasl"
   "Auxlib/load.fasl")
 '(remq! remv! remove! aremq! aremv! aremove! filter find make-list 
   reduce reduce-right fold-left fold-right vector-copy read-line
   pretty-print pretty-line-length file-newer? read-line 
   load load-noisily load-quietly))

"Load and install the debugger"

(load-in-private-namespace
 '("Debugger/debug.fasl"
   "Debugger/inspect-cont.fasl"
   "Debugger/trace.fasl")
 '(debug trace trace-entry trace-exit untrace break-entry unbreak 
   install-debugger))

(install-debugger)
(define install-debugger)

"Install pretty printer as default printer."

(repl-printer
 (lambda (x port)
   (if (not (eq? x (unspecified)))
       (pretty-print x port))))

"Load a bunch of useful things."
;;; FIXME: Some of these files could usefully be loaded in private namespaces.

(load "Auxlib/macros.sch")
(load "Auxlib/record.sch")              ; Record package
;(load "Experimental/define-record.sch") ; DEFINE-RECORD syntax
;(load "Experimental/exception.sch")

;; IAssassin doesn't support the FFI at the moment...
;(load "Auxlib/std-ffi.sch")
;(load "Auxlib/unix-functions.sch")

(load "Experimental/system-stuff.fasl")
;(load "Experimental/applyhook0.fasl")
;(load "Experimental/applyhook.fasl")

"Improve some definitions"

(define (procedure-documentation-string p)
  (let ((e (procedure-expression p)))
    (if (and (list? e)
             (> (length e) 2)
             (string? (caddr e))
             (not (null? (cdddr e))))
        (caddr e)
        #f)))

"Dump the heap"

(gctwa)
(dump-interactive-heap "larceny.heap")
(system "./larceny.bin -reorganize-and-dump -heap larceny.heap")
(system "/bin/mv larceny.heap.split larceny.heap")

; eof