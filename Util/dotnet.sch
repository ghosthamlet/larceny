;; Provides a procedure
;; larceny-setup : host-sym OS-sym -> ???
;;
;; Loads appropriate system-dependent stuff

;; BEFORE LOADING THIS FILE:  Make sure your Scheme interpreter's
;; current-directory is the root of this source tree.

;; TODO:  Umm... finish.  Also, fix nbuild.sch and nbuild-files.sch
;;   Gotta separate the new compiler sources from the old Std. C
;;   and add them to the larceny_src

;; larceny root should be the current directory when the host
;; Scheme system loads this file.
(define *larceny-root* #f)

;; this needs to be global... it floats all around the build-system.
;; it will be set to something meaningful by (larceny-setup ...).
(define nbuild-parameter
  (lambda x (display "!! nbuild-parameter not yet set! (Util/dotnet.sch)")))

(define make-nbuild-parameter
  (lambda x (display "!! make-nbuild-parameter not yet set! (Util/dotnet.sch)")))

;; this needs to be global for the definition of lib-files
(define option:os #f)

(define system-big-endian?
  (lambda x (display "!! system-big-endian not set yet")(newline)))

;; FIXME:  figure out endian from host scheme system?
(define (larceny-setup host os option:endian)
  (set! option:os os)

  (case option:endian
    ((big be) (set! system-big-endian? (lambda () #t)))
    ((little el) (set! system-big-endian? (lambda () #f))))
  
  ;; FIXME:  might have to fudge more this for Cygwin
  ;; load code to work with pathnames
  (case option:os
    ((win32) (load "Util\sysdep-win32.sch"))
    ((unix macosx) (load "Util/sysdep-unix.sch"))
    (else
     (begin (display "Host = ") (display host)
            (error "unknown host!"))))

  (set! *larceny-root* (make-filename ""))

  
  ;; Standard-C version.  Have to fix this once .Net backend
  ;; stops needing to load & mutate the Standard-C backend.  It might also
  ;; be nice if a bunch of the options weren't hardcoded.
  (let ((option:source? #t)
        (option:verbose? #f)
        (option:development? #t))
    ;; set! burns my eyes!
    (set!
     make-nbuild-parameter
     (lambda (dir hostdir hostname)
       (let ((parameters 
              `((compiler       . ,(pathname-append dir "Twobit"))
                (util           . ,(pathname-append dir "Util"))
                (build          . ,(pathname-append dir "Rts" "Build"))
                (source         . ,(pathname-append dir "Lib"))
                (common-source  . ,(pathname-append dir "Lib" "Common"))
                (repl-source    . ,(pathname-append dir "Repl"))
                (interp-source  . ,(pathname-append dir "Interpreter"))
                (machine-source . ,(pathname-append dir "Lib" "Standard-C"))
                (common-asm     . ,(pathname-append dir "Asm" "Common"))
                (standard-C-asm . ,(pathname-append dir "Asm" "Standard-C"))
                (always-source? . ,option:source?)
                (verbose-load?  . ,option:verbose?)
                (development?   . ,option:development?)
                (compatibility  . ,(pathname-append dir "Compat" hostdir))
                (auxiliary      . ,(pathname-append dir "Auxlib"))
                (root           . ,dir)
                (host-system    . ,hostname)
                (target-machine . Standard-C)
                (target-os      . ,option:os)
                (host-os        . ,option:os)
                (endianness     . ,option:endian)
                (target-endianness . ,option:endian)
                (host-endianness . ,option:endian)
                (word-size      . 32)
                )))
         (lambda (key)
           (let ((probe (assq key parameters)))
             (if probe 
                 (cdr probe)
                 #f)))))))
     
  
  ;; set this so everybody can use it
  (set! nbuild-parameter
        (make-nbuild-parameter *larceny-root* host host))

  ;; Load the compatibility file, expander, and config system.
  (load (string-append (nbuild-parameter 'compatibility) "compat.sch"))
  (compat:initialize)
  (load (string-append (nbuild-parameter 'util) "expander.sch"))
  (load (string-append (nbuild-parameter 'util) "config.sch"))
  (set! config-path "Rts/Build/")
  (load (string-append (nbuild-parameter 'util) "csharp-config.scm"))
  )

(define (setup-directory-structure)
  (make-directory* (build-path *root-directory* "Rts" "Build")))


(define (build-config-files)
  ;; Generate the C# code for the constant definitions.
  (define run-csharp-config
    (let ((output-c#-file
           (make-filename *larceny-root* "Rts" "DotNet" "Constants.cs"))
          (rts-dir (make-filename *larceny-root* "Rts")))
      (lambda ()
        (csharp-config 
         output-c#-file
         `((,(make-filename rts-dir "layouts.cfg")  int)
           (,(make-filename rts-dir "except.cfg")  uint)
           (,(make-filename rts-dir "globals.cfg") uint)
           (,(make-filename rts-dir "mprocs.cfg")  uint))))))
      
  (define (catfiles input-files output-file)
    (with-output-to-file output-file
      (lambda ()
        (for-each
         (lambda (infile)
           (with-input-from-file infile
             (lambda ()
               (let loop ()
                 (let ((next (read-char)))
                   (unless (eof-object? next)
                     (write-char next)
                     (loop)))))))
         input-files))))
  
  ;; FIXME:  not portable.
  (parameterize [(current-directory (make-filename *root-directory* "Rts"))]
    (for-each
     (lambda (cfgfile) 
       (unless (file-exists? (build-path "Build" cfgfile))
         (copy-file (build-path cfgfile) 
                    (build-path "Build" cfgfile))))
     (filter (lambda (file) (regexp-match "\\.cfg$" file))
             (directory-list)))
    
    ;; we don't care about C.
    ;;(expand-file (build-path "Standard-C" "arithmetic.mac")
    ;;             (build-path "Standard-C" "arithmetic.c"))

    (parameterize [(current-directory *root-directory*)]
      (for-each config
                (map (lambda (f) (make-filename *root-directory* "Rts" f))
                     '("except.cfg" "globals.cfg" "layouts.cfg" "mprocs.cfg")))
      (catfiles '("globals.ch"
                  "except.ch"
                  "layouts.ch"
                  "mprocs.ch")
                (build-path "Rts" "Build" "cdefs.h"))
      (catfiles '("globals.sh" 
                  "except.sh" 
                  "layouts.sh")
                (build-path "Rts" "Build" "schdefs.h")))
    (run-csharp-config)))


;; Load the compiler
(define (load-twobit)
  (load (make-filename *larceny-root* "Util" "nbuild.sch")))

(define (ensure-build-environment)
  (unless (directory-exists? (build-path *root-directory* "Rts" "Build"))
    (printf "Setting up directories~n")
    (setup-directory-structure))
  (unless (andmap file-exists?
                  (map (lambda (f) 
                         (build-path *root-directory* "Rts" "Build" f))
                       '("cdefs.h" "schdefs.h")))
    (printf "Building config files~n")
    (build-config-files)))

(define (lib-files)
  `[("primops" 
     ,(if (eq? option:os 'win32) "sys-win32" "sys-unix") 
     "list" "except.sh" "globals.sh" "malcode" 
     ;; "arith"  ;; Arith introduces generic+, which is not defined anywhere
     "sysparam" "vector")
    ("belle" 
     ,(if (system-big-endian?) "bignums-be" "bignums-el")
     "bignums" "command-line" "conio" "contag" 
     "control" "dump" "ehandler" "env" "error0" "error" "eval" "exit"
     "fileio" 
     ,(if (system-big-endian?) "flonums-be" "flonums-el") 
     "flonums" "format" "gcctl" "go" "hash" "hashtable"
     "load" "memstats" "num2str" "number" "oblist" "preds" "print" 
     "procinfo" "profile" "ratnums" "reader" "rectnums" "secret" "sort"
     "str2num" "string" "stringio" "struct" "syscall-id" 
     "syshooks" "system-interface" "timer" "toplevel"
     "transio" "typetags")
    ("iosys" "stdio" "ioboot" "mcode")])

(define (lib-il-files)
  '("loadable" "toplevel-target"))

(define (repl-files)
  '("main" "reploop" "interp" "interp-prim" "switches" 
    "pass1" "pass1.aux" "pass2.aux" "prefs" 
    "syntaxenv" "syntaxrules" "lowlevel" "expand" "usual"
    "macro-expand"))

(define (create-application app src-manifests)
  (define app-exe (string-append app ".exe"))
  (define app-il (string-append app ".il"))
  (define ordered-il-files
    (map (lambda (f) (rewrite-file-type f ".manifest" ".code-il"))
         src-manifests))
  (define assembly-il 
    (create-assembly app-exe src-manifests))
  (concatenate-files app-il (cons assembly-il ordered-il-files)))

;(define (create-standard-library)
;  (parameterize [(current-directory
;                  (build-path LARCENY-PATH "Lib"))]
;    (define files 
;      (append (map (lambda (f) (build-path "Common" (string-append f ".manifest")))
;                   (apply append (lib-files)))
;              (map (lambda (f) (build-path "IL" (string-append f ".manifest")))
;                   (lib-il-files)))
;    (create-application "Lib" files)))

(define (create-standard-library)
  (define files
    (append (map (lambda (f)
                   (make-filename *larceny-root*
                                  "Lib"
                                  "Common"
                                  (string-append f ".manifest")))
                 (apply append (lib-files)))
            (map (lambda (f)
                   (make-filename *larceny-root*
                                  "Lib"
                                  "IL"
                                  (string-append f ".manifest")))
                 (lib-il-files))))
  ;; Lib appears twice... first says use the "Lib" subdirectory
  ;; second says to create "Lib.il"
  (create-application (make-filename *larceny-root* "Lib" "Lib") files))

;; FIXME:  should look more like create-standard-library.
;;         Also, need to add "More" to larceny_src tree
(define (create-repl)
  (parameterize [(current-directory
                  (build-path LARCENY-PATH "Lib"))]
    (define files 
      (map (lambda (f) (build-path "More" (string-append f ".manifest")))
           repl-files))
    (create-application "Repl" files)))

(define (concatenate-files target sources)
  (with-output-to-file target
    (lambda ()
      (for-each display-file sources))))

;; read-string isn't portable
;(define (display-file source)
;  (with-input-from-file source
;    (lambda ()
;      (let loop ()
;        (let [(next (read-string 1024))]
;          (if (eof-object? next)
;              #t
;              (begin
;                (display next)
;                (loop))))))))

(define (display-file source)
  (with-input-from-file source
    (lambda ()
      (let loop ()
        (let ((next (read-char)))
          (if (eof-object? next)
              #t
              (begin
                (display next)
                (loop))))))))
