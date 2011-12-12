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

(define-module (ragnarok error)
  #:use-module (ragnarok utils)
  #:export (ragnarok-try)
  )

(define-syntax ragnarok-try
  (syntax-rules (catch throw final)
    ((_ *thunk* catch *exception* throw *handler*)
     (catch *exception* *thunk* *handler*))
    ((_ *thunk1* catch *exception* throw *handler* final *thunk2*)
     (catch *exception* *thunk1* (lambda (k . e)
				   (*handler* k e)
				   (*thunk2*))))
    ))
	    

