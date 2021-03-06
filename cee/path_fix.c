/*	
 *  Copyright (C) 2011
 *	"Mu Lei" known as "NalaGinrut" <NalaGinrut@gmail.com>
 
 *  Ragnarok is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 
 *  Ragnarok is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <libguile.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

#define MAX_PATH_LEN 4096 // exceeded would be cut

#define NORMAL 1
#define RELATIVE 2
#define LAST 0
#define END 0

#define IS_END(str) (*(str) == '\0')

#define IS_RELATIVE(path) \
  ((path)[1] == '.' && (path)[2] == '.' \
   && ((path)[3] == '/' || (path)[3] == '\0'))

#define NEED_FIX(path) \
  ((path)[0] != '\0' && (path)[1] == '.' \
   && (path)[2] == '.' && (path)[3] == '/')
  
static inline char* fix_prefix(const char* path)
{
  /* NOTE: delete ".." in prefix
   */
  const char* ptr = path;

  while(NEED_FIX(ptr))
    {
      ptr += 3;
    }
  
  return (char*)ptr;
}
  
static inline int drop_last_dir(char* path)
{
  char* ptr = path-1;

  if(ptr[0] == '\n')
    return 0;
    
  while(*ptr != '/')
    ptr--;

  return path - ptr;
}

static inline int get_dir(const char* path ,char* buf ,int* pi ,int* bi)
{
  const char* head = NULL;
  const char* tail = NULL;
  int len = 0;
  int path_len = 0;
  int ret = 0;
  
  if(IS_END(path))
    return END;

  path += *pi;
  buf += *bi;
  
  path_len = strlen(path);
  head = path;
  tail = (path_len-1) >= 0 ? memchr(path+1 ,'/' ,path_len-1) : NULL;

  if(!tail)  // so it must be the last dir
    {
      len = path_len;

      if(IS_RELATIVE(head))
	{
	  buf -= drop_last_dir(buf);
	  buf[0] = '\0';
	  return END;
	}
      
      buf[len] = '\0'; // end fixed string
      ret = LAST;
    }
  else if(IS_RELATIVE(head))
    {
      *bi -= drop_last_dir(buf);
      *pi += 3; // length of "/.."
      return RELATIVE;
    }
  else // not relative path
    {
      len = tail - head;
      ret = NORMAL;
    }

  memcpy(buf ,head ,len);
  *bi += len;
  *pi += len;
  
  return ret;
}

SCM scm_mmr_path_fix(SCM target)
#define FUNC_NAME "path-fix"
{
  char *path = NULL;
  char *fixed = NULL; // fixed path
  char *tmp = NULL;
  int path_len = 0;
  int bi = 0;
  int pi = 0;
  SCM ret;
  
  SCM_VALIDATE_STRING(1 ,target);

  scm_dynwind_begin(0);
  
  path = scm_to_locale_string(target);
  scm_dynwind_free(path);

  if(!strstr(path ,"/.."))
    {
      // no relative path
      ret = target;
      goto end;
    }

  path_len = strlen(path);
  path_len = path_len>MAX_PATH_LEN? MAX_PATH_LEN : path_len;
  fixed = (char *)malloc(path_len+1);
  fixed[0] = '\n'; // sentinal

  while(get_dir(path ,fixed+1 ,&pi ,&bi))
    {}

  /* NOTE: The result won't contain '/' at the end,
   * because we'll append *path '/' filename* finally.
   */

  tmp = fix_prefix(fixed+1);
  ret = scm_from_locale_string(tmp);

  free(fixed);
  fixed = NULL;
  tmp = NULL;

 end:
  scm_dynwind_end();
  return ret;
}
#undef FUNC_NAME
  
#ifdef __cplusplus
}
#endif

// TODO: regenerate a valid path from request's path
//	 1. cut off all the "..";
//	 2. keep path within the root path;
//	 3. deal with relative path



