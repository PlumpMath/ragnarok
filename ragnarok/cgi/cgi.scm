;;  Copyright (C) 2011-2012
;;      "Mu Lei" known as "NalaGinrut" <NalaGinrut@gmail.com>
;;  Ragnarok is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.

;;  Ragnarok is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.

;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.

(define-module (ragnarok cgi cgi)
  #:use-module (ragnarok protocol http status)
  #:use-module (ragnarok utils)
  #:use-module (ragnarok info)
  #:use-module (ragnarok version)
  #:use-module (srfi srfi-9)
  #:use-module (ice-9 popen)
  #:export (make-cgi-record
	    file-stat:size
	    record-real-bv-size
	    cgi:env-table
	    cgi:target
	    cgi:conn-socket
	    cgi-record?
	    cgi-env-set!
	    create-cgi
	    regular-cgi-run
	    ragnarok-regular-cgi-handler
	    http-make-cgi-type
	    create-cgi-env-table
	    cgi:auth-type! 
	    cgi:content-length!
	    cgi:content-type!
	    cgi:gateway-interface!
	    cgi:path-info! 
	    cgi:path-translated!
	    cgi:query-string!
	    cgi:remote-addr! 
	    cgi:remote-host! 
	    cgi:remote-ident!
	    cgi:remote-user! 
	    cgi:request-method!
	    cgi:script-name! 
	    cgi:server-name! 
	    cgi:server-port! 
	    cgi:server-protocol!
	    cgi:server-software!))

;; NOTE: We must return file-stat as one of values, but the stat:size is not
;;       the real size of dynamic page. So we modify the stat:size.
(define file-stat:size 7)
(define record-real-bv-size
  (lambda (st size)
    (vector-set! st file-stat:size size)
    st))

(define *cgi-env-vars-numbers* 17)
(define (create-cgi-env-table)
  (make-hash-table *cgi-env-vars-numbers*))

;; WARN: DO NOT change the order of *cgi-env-vars-list*.
(define *cgi-env-vars-list*
  '("AUTH_TYPE"
    "CONTENT_LENGTH"
    "CONTENT_TYPE"
    "GATEWAY_INTERFACE"
    "PATH_INFO"
    "PATH_TRANSLATED"
    "QUERY_STRING"
    "REMOTE_ADDR"
    "REMOTE_HOST"
    "REMOTE_IDENT"
    "REMOTE_USER"
    "REQUEST_METHOD"
    "SCRIPT_NAME"
    "SERVER_NAME"
    "SERVER_PORT"
    "SERVER_PROTOCOL"
    "SERVER_SOFTWARE"))


(define-record-type cgi-record
  (make-cgi-record target env-table conn-socket)
  cgi-record?
  (target cgi:target)
  (env-table cgi:env-table) ;; a hash table to put envion vars
  (conn-socket cgi:conn-socket))

(define http-make-cgi-type
  (lambda (fixed-target server-info)
    (let* ([conn-socket (server-info:connect-socket server-info)]
	   [remote-info (server-info:remote-info server-info)]
	   [auth-type (remote-info:auth-type remote-info)]
	   [content-length (remote-info:content-length remote-info)]
	   [content-type (remote-info:content-type remote-info)]
	   ;;[gateway-interface #f]
	   ;;[path-info #f]
	   ;;[path-translated #f]
	   [query-string (remote-info:query-string remote-info)]
	   [remote-addr (remote-info:remote-addr remote-info)]
	   [remote-host (remote-info:remote-host remote-info)]
	   ;;[remote-ident #f]
	   [remote-user (remote-info:remote-user remote-info)]
	   [request-method (remote-info:request-method remote-info)]
	   [script-name (remote-info:target remote-info)]
	   [subserver-info (server-info:subserver-info server-info)]
	   [server-name (subserver-info:server-name subserver-info)]
	   [server-port (subserver-info:server-port subserver-info)]
	   [server-protocol 
	    (subserver-info:server-protocol subserver-info)]
	   [server-software 
	    (subserver-info:server-software subserver-info)] 
	   [env-table (create-cgi-env-table)])
      (create-cgi fixed-target conn-socket 
		  #:QUERY_STRING query-string
		  #:REQUEST_METHOD request-method
		  #:AUTH_TYPE auth-type
		  #:CONTENT_LENGTH content-length
		  #:CONTENT_TYPE content-type
		  ;;#:GATEWAY_INTERFACE gateway-interface
		  ;;#:PATH_INFO path-info
		  ;;#:PATH_TRANSLATED path-translated
		  #:REMOTE_ADDR remote-addr
		  #:REMOTE_HOST remote-host
		  ;;#:REMOTE_IDENT remote-ident
		  #:REMOTE_USER remote-user
		  #:SCRIPT_NAME script-name
		  #:SERVER_NAME server-name
		  #:SERVER_PORT server-port
		  #:SERVER_PROTOCOL server-protocol
		  #:SERVER_SOFTWARE server-software))))

(define create-cgi
  (lambda* 
   (target conn-socket 
	   #:key 
	   (QUERY_STRING "")
	   (REQUEST_METHOD "GET")
	   (AUTH_TYPE "Basic")
	   (CONTENT_LENGTH "")
	   (CONTENT_TYPE "")
	   (GATEWAY_INTERFACE "CGI/1.1")
	   (PATH_INFO "")
	   (PATH_TRANSLATED "")
	   (REMOTE_ADDR "")
	   (REMOTE_HOST "")
	   (REMOTE_IDENT "")
	   (REMOTE_USER "")
	   (SCRIPT_NAME "")
	   (SERVER_NAME "")
	   (SERVER_PORT "80")
	   (SERVER_PROTOCOL "http")
	   (SERVER_SOFTWARE *ragnarok-version*))
  ;; WARN: DO NOT change this order.
  (let* ([vl `(,AUTH_TYPE
	       ,CONTENT_LENGTH
	       ,CONTENT_TYPE
	       ,GATEWAY_INTERFACE
	       ,PATH_INFO
	       ,PATH_TRANSLATED
	       ,QUERY_STRING
	       ,REMOTE_ADDR
	       ,REMOTE_HOST
	       ,REMOTE_IDENT
	       ,REMOTE_USER
	       ,REQUEST_METHOD
	       ,SCRIPT_NAME
	       ,SERVER_NAME
	       ,SERVER_PORT
	       ,SERVER_PROTOCOL
	       ,SERVER_SOFTWARE)]
	 [env-table (make-hash-table *cgi-env-vars-numbers*)])
     
    (for-each (lambda (k v)
		(hash-set! env-table k v))
	      *cgi-env-vars-list*
	      vl)
    
    (make-cgi-record target
		     env-table
		     conn-socket))))

(define cgi-env-get
  (lambda (key cgi)
    (let ([env-table (cgi:env-table cgi)])
      (hash-ref env-table key))))

(define cgi-env-set!
  (lambda (cgi key value)
    (let ([env-table (cgi:env-table cgi)])
      (hash-set! env-table key value))))

(define-syntax-rule (generate-cgi-cmd cgi)
  (let ([QUERY_STRING (cgi-env-get "QUERY_STRING" cgi)]
	[conn-socket (cgi:conn-socket cgi)])
    ;; if QUERY_STRING is not #f ,that means method is POST
    ;; FIXME: we should use REQUEST_METHOD to decide.
    (if QUERY_STRING
	(begin
	  (redirect-port conn-socket (current-input-port))
	  (string-append "QUERY_STRING=" QUERY_STRING))
	"")))
	  
(define regular-cgi-run
  (lambda (cgi charset)
    (assert (cgi-record? cgi))
    (let* ([target (cgi:target cgi)]
	   [envs (generate-cgi-cmd QUERY_STRING)]
	   [pipe (open-pipe* OPEN_BOTH envs target)])

      ;; set charset
      (set-port-encoding! pipe charset)
       
      (let* ([bv (get-bytevector-all pipe)]
	     [size (bytevector-length bv)]
	     [fst (stat (cgi:target cgi))])
	(close pipe)
	(values bv
		*OK*
		(record-real-bv-size fst size))))))
		    
(define ragnarok-regular-cgi-handler
  (lambda (cgi charset)
    (assert (cgi-record? cgi))
    (if (not (check-file-perms (cgi:target cgi) #o555)) ;; DON'T use "access?"
	(values #f *Forbidden* #f) ;; no excute perms
	(regular-cgi-run cgi charset))))

(define (cgi:auth-type! cgi-env-table v)
  (hash-set! cgi-env-table "AUTH_TYPE" v))

(define (cgi:content-length! cgi-env-table v)
  (hash-set! cgi-env-table "CONTENT_LENGTH" v))

(define (cgi:content-type! cgi-env-table v)
  (hash-set! cgi-env-table "CONTENT_TYPE" v))

(define (cgi:gateway-interface! cgi-env-table v)
  (hash-set! cgi-env-table "GATEWAY_INTERFACE" v))

(define (cgi:path-info! cgi-env-table v)
  (hash-set! cgi-env-table "PATH_INFO" v))

(define (cgi:path-translated! cgi-env-table v)
  (hash-set! cgi-env-table "PATH_TRANSLATED" v))

(define (cgi:query-string! cgi-env-table v)
  (hash-set! cgi-env-table "QUERY_STRING" v))

(define (cgi:remote-addr! cgi-env-table v)
  (hash-set! cgi-env-table "REMOTE_ADDR" v))

(define (cgi:remote-host! cgi-env-table v)
  (hash-set! cgi-env-table "REMOTE_HOST" v))

(define (cgi:remote-ident! cgi-env-table v)
  (hash-set! cgi-env-table "REMOTE_IDENT" v))

(define (cgi:remote-user! cgi-env-table v)
  (hash-set! cgi-env-table "REMOTE_USER" v))

(define (cgi:request-method! cgi-env-table v)
  (hash-set! cgi-env-table "REQUEST_METHOD" v))

(define (cgi:script-name! cgi-env-table v)
  (hash-set! cgi-env-table "SCRIPT_NAME" v))

(define (cgi:server-name! cgi-env-table v)
  (hash-set! cgi-env-table "SERVER_NAME" v))

(define (cgi:server-port! cgi-env-table v)
  (hash-set! cgi-env-table "SERVER_PORT" v))

(define (cgi:server-protocol! cgi-env-table v)
  (hash-set! cgi-env-table "SERVER_PROTOCOL" v))

(define (cgi:server-software! cgi-env-table v)
  (hash-set! cgi-env-table "SERVER_SOFTWARE" v))

	   
