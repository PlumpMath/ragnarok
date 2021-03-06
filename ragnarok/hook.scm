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

(define-module (ragnarok hook)
  #:export (hook-list-init))

(define *hook-list*
  `((http ,(@ (ragnarok protocol http hook) init-hook))
    (eips ,(@ (ragnarok protocol eips hook) init-hook))))

(define (hook-list-init)
  (for-each (lambda (hk)
	      (apply (cadr hk) '()))
	    *hook-list*))

