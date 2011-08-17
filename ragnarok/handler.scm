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

(define-module (ragnarok handler)
  #:use-module (ragnarok utils)
  #:export (get-handler 
	    handler-register
	    *handler-list*)
  )

(define *handler-list* '())

(define-syntax handler-register 
  (syntax-rules () 
    ((_ proto handler)
     (add-to-list! *handler-list*
		   proto
		   handler)
     )))

(define get-handler
  (lambda (protocol)
    (or (symbol? protocol)
	(error get-handler "invalid type, should be symbol:" protocol))
    (get-arg *handler-list* protocol)))



