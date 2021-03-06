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

(define-module (ragnarok msg)
  #:use-module (srfi srfi-9))

(module-export-all! (current-module))

(define-record-type log-msg
  (make-log-msg time type info)
  log-msg?
  (time msg:time msg:time!)
  (type msg:type msg:type!)
  (info msg:info msg:info!))

(define-record-type err-msg
  (make-err-msg time status)
  err-msg?
  (time emsg:time)
  (status emsg:status))

;; NOTE: This time stamp only used for local log record, 
;;       so we could use locale-specific procedure 'strftime'.
(define (msg-time-stamp)
  (strftime "%c" (localtime (current-time))))
