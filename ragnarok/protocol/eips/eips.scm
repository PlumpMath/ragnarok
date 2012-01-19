;;  Copyright (C) 2012  
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

(define-module (ragnarok protocol eips)
  #:use-module (ragnarok utils)
  #:use-module (oop goops)
  #:export (eips-handler)
  )

(define eips-handler 
  (lambda (logger client-connection subserver-info)
    #t
    ))

(define-class <eips> (<protocol>)
  ;; TODO: finish <eips> class
  (charset #:init-value "utf-8" #:accessor eips:charset)
  (target #:init-value #f #:accessor eips:target)
  )

(define-method eips:run (self <eips>)
  (let* ([p-buf (pipe)]
	 [r (car p-buf)]
	 [w (cdr p-buf)]
	 [i (ragnarok-fork)]
	 [charset (eips:charset self)]
	 [target (eips:target eips)]
	 [conn-socket (protocol:conn-socket eips)]
	 )

    (cond
     ((not (file-exists? target))
      (ragnarok-throw "target: ~a doesn't exist!~%" target))
     ((not (check-file-perms target #o555)) ;; DON'T use "access?"
      (ragnarok-throw "target: ~a doesn't have X permission!~%" target)))

    ;; set charset
    (set-port-encoding! w charset)
    (set-port-encoding! r charset)

    (cond 
     ((< i 0)
      (values #f *Fork-Error* #f))
     ((= i 0)
      (setvbuf w _IONBF) ;; set to block buffer
      (redirect-port w (current-output-port))
      ;; NOTE: conn-socket must be the input-port
      (redirect-port conn-socket (current-input-port))
      (execle target (environ)) ;; run eip
      (close (current-output-port))
      ))
    
    ;; NOTE: parent must wait child terminate, 
    ;;       or get-bytevector-all will be blocked.
    (ragnarok-waitpid i)
    
    ;; NOTE: we must close input pipe ,or get-bytevector-all will be blocked.
    ;; I wonder if this is a bug.
    (close w) 
 
    ;; NOTE: return as bytevector
    (get-bytevector-all r)
    ))

