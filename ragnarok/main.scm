;;  Copyright (C) 2011  
;;      "Mu Lei" known as "NalaGinrut" <NalaGinrut@gmail.com>
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.

;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.

;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.

(define-module (ragnarok main)
  #:use-module (ragnarok env)
  #:use-module (ragnarok server)
  #:use-module (ragnarok version)
  #:use-module (ragnarok utils)
  #:use-module (oop goops)
  #:use-module (ice-9 getopt-long)
  #:export (main)
  )

(define ragnarok-env (make <env>))

(define *ragnarok-running-dir* "/var/log/ragnarok")
(define make-ragnarok-sys-file
  (lambda (filename)
    (string-append *ragnarok-running-dir* "/" filename)))
(define *ragnarok-lock-file* 
  (make-ragnarok-sys-file "ragnarok.lock"))
(define *ragnarok-log-file* 
  (make-ragnarok-sys-file "ragnarok.log"))
(define *ragnarok-err-log-file* 
  (make-ragnarok-sys-file "ragnarok.err"))

(define (ragnarok-unlock)
  (let ([lfp (open *ragnarok-lock-file* O_RDWR)])
    (flock lfp LOCK_UN)
    (close lfp))
  (delete-file *ragnarok-lock-file*))

(define option-spec
  '((version (single-char #\v) (value #f))
    (help (single-char #\h) (value #f))
    (config (single-char #\c) (value #f)) ;; specify config file
    (server (single-char #\s) (value #f)) ;; specify sub-servers to start
    ))

(define help-str
  "
Ragnarok is a generic server written with GNU/Guile and C.
Ragnarok supports http/1.1 originally now. You may define your own protocol to Ragnarok by protobuf-r6rs(coming soon).

Usage: ragnarok [OPTIONS]...

--help -h: Show this screen.
--version -v: Show version.
--config -c: Specify config file.
--server -s: Specify sub-servers to start which delimited by ','.

Any bug/improve report will be appreciated.
Author: NalaGinrut@gmail.com
God bless hacking.\n
")

(define version-str
  (format #f 
	  "
~a. 

Copyright (C) 2011 Mu Lei known as \"NalaGinrut\" <NalaGinrut@gmail.com>
License LGPLv3+: GNU LGPL 3 or later <http://gnu.org/licenses/lgpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

God bless hacking."
	  ragnarok-version))

(define (ragnarok-terminate)
  (kill (getpid) SIGTERM))

(define (show-help)
  (display help-str)
  (exit)
  )

(define (show-version)
  (display version-str)
  (exit)
  )

(define ragnarok-log-message
  (lambda (message)
    (let* ([lf (open-file *ragnarok-log-file* "a")]
	  [cgt (get-global-current-time)]
	  )
      (if lf
	  (format lf "~a at ~a~%" message cgt))
      (close lf)
      )))

(define (ragnarok-kill-all-servers)
  (let ([server-list (env:server-list ragnarok-env)])
    (for-each (lambda (s-pair)
		(server:down (cdr s-pair)))
	      server-list)))

(define (ragnarok-terminate-environ)
  ;; TODO: terminate environ
  (ragnarok-kill-all-servers)
  )

(define ragnarok-SIGHUP-handler
  (lambda (msg)
    (ragnarok-log-message "Ragnarok hangup!")
    ;; TODO: deal with hangup
    ))

(define ragnarok-SIGTERM-handler
  (lambda (msg)
    (ragnarok-log-message "Ragnarok exit!");
    (ragnarok-terminate-environ)
    (ragnarok-unlock)
    (sync)
    ;;(format #t "well~quit")
    (exit)
    ))

(define (signal-register)
  (sigaction SIGCHLD SIG_IGN) ;; ignore child
  (sigaction SIGTSTP SIG_IGN) ;; ignore tty signals
  (sigaction SIGTTOU SIG_IGN) ;; 
  (sigaction SIGTTIN SIG_IGN) ;;
  (sigaction SIGHUP ragnarok-SIGHUP-handler) ;; catch hangup signal
  (sigaction SIGTERM ragnarok-SIGTERM-handler) ;; catch kill signal
  )

(define main
  (lambda (args)
    (let* ((options 
            (getopt-long args option-spec))
           (need-help?
            (option-ref options 'help #f))
           (need-version?
            (option-ref options 'version #f))
	   (config-file
	    (option-ref options 'config "/etc/ragnarok/server.conf"))
	   (server-list
	    (option-ref options 'server #f))
	   )

      (cond
       (need-help? (show-help))
       (need-version? (show-version)))
      
      ;; daemonize
      (let ([i (primitive-fork)])
	(cond
	 ((> i 0) (exit)) ;; exit parent
	 ((< i 0) (error "Ragnarok: fork error!")))
	)

      ;; child(daemon) continue
      (setsid)
      (chdir *ragnarok-running-dir*)

      (let* ([i (open "/dev/null" O_RDWR)]
	     [e (open *ragnarok-err-log-file* (logior O_CREAT O_RDWR))] 
	     [lfp (open *ragnarok-lock-file* 
			(logior O_RDWR O_CREAT)
			#o640)]
	     )
	
	;;(for-each close (iota 3)) ;; close all ports
	(redirect-port i (current-input-port)) ;; stdin
	(redirect-port e (current-output-port))
	(redirect-port e (current-error-port)) ;; stderr
	(umask 022)
	
	(if (< (port->fdes lfp) 0)
	    (begin
	      (display "Ragnarok: can not open/create lock file!\n")
	      (exit 2)))

	(flock lfp LOCK_EX)
	
	(write (getpid) lfp)
	(close lfp)
	)

      ;; TODO: signal handler register
      (signal-register)

      ;; TODO: overload cmd parameters to default parameters
      ;;       #f for default ,otherwise overload it.

      (let ((server (make <server>)))
	(server:run server))
    )))