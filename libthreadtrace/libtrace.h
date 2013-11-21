#ifndef __LIBTRACE_H__
#define __LIBTRACE_H__

#ifdef __cplusplus
extern "C" {
#endif

#include <bfd.h>
#define PROGRAM_NAME "libtrace"

/* Initialize libtrace with file file_name and section section_name. */
int libtrace_init
   (const char *file_name,
    const char *section_name,
    const char *target);

/* Close libtrace. */
int libtrace_close
   (void);

/* Translate xaddr into optionally file_name:line_number or function name.  */
void libtrace_translate_addresses
   (void *xaddr,
    char *func_buf, size_t func_buf_len, 
    char *site_buf, size_t site_buf_len);

#ifdef __cplusplus
}
#endif
#endif

