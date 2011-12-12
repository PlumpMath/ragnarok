/*	
 *  Copyright (C) 2011
 *	"Mu Lei" known as "NalaGinrut" <NalaGinrut@gmail.com>
 
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef __RAGNAROK_ERROR_H__
#define __RAGNAROK_ERROR_H__

#define RAG_ERROR(proc ,msg ,arg ,rest) 		\
  scm_error(scm_string_to_symbol("ragnarok-error") ,proc ,msg ,arg ,rest)

#define RAG_ERROR1(proc ,msg ,arg) 		\
  scm_error(scm_string_to_symbol("ragnarok-error") ,proc ,msg ,arg ,SCM_EOL)



#endif // End of __RAGNAROK_ERROR_H__;
