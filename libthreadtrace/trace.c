/* 
 * Derived from addr2line.c and associated binutils files, version 2.22. 
 */

#include <limits.h>
#include <stdio.h>
#include <sysdep.h>
#include <getopt.h>

/*
#pragma GCC visibility push(hidden)
*/
#include <bfd.h>
#include <libiberty.h>
#include <demangle.h>
#include <bucomm.h>
#include <elf-bfd.h>
#ifdef HAVE_ZLIB_H
#include <zlib.h>
#endif
/*
#pragma GCC visibility pop
*/

#include <libtrace.h>
char *program_name = PROGRAM_NAME;

static bfd *abfd;		/* BFD */
static asection *section;	/* File section pointer */
static asymbol **syms;		/* Symbol table.  */

/* These global variables are used to pass information between
   libtrace_translate_addresses and find_address_in_section.  */
static bfd_vma pc;
static const char *filename;
static const char *functionname;
static unsigned int line;
static bfd_boolean found;


/* Read in the symbol table.  */

static int
slurp_symtab (bfd *abfd)
{
  long storage;
  long symcount;
  bfd_boolean dynamic = FALSE;

  if ((bfd_get_file_flags (abfd) & HAS_SYMS) == 0)
    return 0;

  storage = bfd_get_symtab_upper_bound (abfd);
  if (storage == 0) {
    storage = bfd_get_dynamic_symtab_upper_bound (abfd);
    dynamic = TRUE;
  }
  if (storage < 0) {
    bfd_nonfatal (bfd_get_filename (abfd));
    return -1;
  }

  syms = (asymbol **) xmalloc (storage);
  if (dynamic)
    symcount = bfd_canonicalize_dynamic_symtab (abfd, syms);
  else
    symcount = bfd_canonicalize_symtab (abfd, syms);
  if (symcount < 0) {
    bfd_nonfatal (bfd_get_filename (abfd));
    return -1;
  }

  return 0;
}


/* Look for an address in a section.  This is called via
   bfd_map_over_sections.  */

static void
find_address_in_section (bfd *abfd, asection *section,
			 void *data ATTRIBUTE_UNUSED)
{
  bfd_vma vma;
  bfd_size_type size;

  if (found)
    return;

  if ((bfd_get_section_flags (abfd, section) & SEC_ALLOC) == 0)
    return;

  vma = bfd_get_section_vma (abfd, section);
  if (pc < vma)
    return;

  size = bfd_get_section_size (section);
  if (pc >= vma + size)
    return;

  found = bfd_find_nearest_line (abfd, section, syms, pc - vma,
				 &filename, &functionname, &line);
}


/* Look for an offset in a section.  This is directly called.  */

static void
find_offset_in_section (bfd *abfd, asection *section)
{
  bfd_size_type size;

  if (found)
    return;

  if ((bfd_get_section_flags (abfd, section) & SEC_ALLOC) == 0)
    return;

  size = bfd_get_section_size (section);
  if (pc >= size)
    return;

  found = bfd_find_nearest_line (abfd, section, syms, pc,
				 &filename, &functionname, &line);
}


/** libtrace.h functions **/
/* Initialize libtrace with file file_name and section section_name. */

int
libtrace_init(
          const char *file_name, 
          const char *section_name,
          const char *target)
{
  xmalloc_set_program_name (program_name);
  bfd_init ();
  set_default_bfd_target ();

  char **matching = NULL;

  if (get_file_size(file_name) < 1)
    return -1;

  abfd = bfd_openr (file_name, target);

  if (abfd == NULL) {
    bfd_nonfatal (file_name);
    return -1;
  }

  /* Decompress sections.  */
  /* abfd->flags |= BFD_DECOMPRESS; */

  if (bfd_check_format (abfd, bfd_archive)) {
    non_fatal (_("%s: cannot get addresses from archive"), file_name);
    return -1;
  }

  if (! bfd_check_format_matches (abfd, bfd_object, &matching)) {
    bfd_nonfatal (bfd_get_filename (abfd));
    if (bfd_get_error () == bfd_error_file_ambiguously_recognized) {
      list_matching_formats (matching);
      free (matching);
    }
    return -1;
  }

  if (section_name != NULL) {
    section = bfd_get_section_by_name (abfd, section_name);
    if (section == NULL) {
      non_fatal (_("%s: cannot find section %s"), file_name, section_name);
      return -1;
    }
  } else
    section = NULL;

  if (0 != slurp_symtab (abfd))
    return -1;

  return 0;
}


/* Close libtrace. */

int
libtrace_close(void)
{
  if (syms != NULL) {
    free (syms);
    syms = NULL;
  }

  bfd_close (abfd);

  return 0;
}


/* Translate xaddr into
   file_name:line_number and optionally function name.  */

void
libtrace_translate_addresses (
		void *xaddr,
		char *func_buf, size_t func_buf_len,
		char *site_buf, size_t site_buf_len)
{
  const struct elf_backend_data * bed;

  #define ADDR_BUF_LEN ((CHAR_BIT/4)*(sizeof(void*))+1)
  char addr[ADDR_BUF_LEN+1] = {0};

  sprintf(addr, "%p", xaddr);
  pc = bfd_scan_vma (addr, NULL, 16);

  if (bfd_get_flavour (abfd) == bfd_target_elf_flavour
	&& (bed = get_elf_backend_data (abfd)) != NULL
	&& bed->sign_extend_vma
	&& (pc & (bfd_vma) 1 << (bed->s->arch_size - 1)))
    pc |= ((bfd_vma) - 1) << bed->s->arch_size;

  found = FALSE;
  if (section)
    find_offset_in_section (abfd, section);
  else
    bfd_map_over_sections (abfd, find_address_in_section, NULL);

  if (!found) {
    if (func_buf != NULL)
      snprintf (func_buf, func_buf_len, "??");
    if (site_buf != NULL)
      snprintf (site_buf, site_buf_len, "??:??");
  }

  /* function name section */
  if (func_buf != NULL) {
    const char *name = functionname;
    char *alloc = NULL;
    if (name == NULL || *name == '\0')
      name = "??";
    else {
      alloc = bfd_demangle (abfd, name, DMGL_ANSI | DMGL_PARAMS);
      if (alloc != NULL)
        name = alloc;
    }

    snprintf (func_buf, func_buf_len, "%s", name);

    if (alloc != NULL)
      free (alloc);
  }

  /* file and line number section */
  if (site_buf != NULL) {
    if (filename == NULL)
      snprintf (site_buf, site_buf_len, "??:??");
    else {
      char *h;
      h = strrchr (filename, '/');
      if (h != NULL)
        filename = h + 1;

      snprintf (site_buf, site_buf_len, "%s:%u", filename, line);
    }
  }

  found = FALSE;
}


/* Imported from binutils/bucomm.c */

void
bfd_nonfatal (const char *string)
{
  const char *errmsg;

  errmsg = bfd_errmsg (bfd_get_error ());
  fflush (stdout);
  if (string)
    fprintf (stderr, "%s: %s: %s\n", program_name, string, errmsg);
  else
    fprintf (stderr, "%s: %s\n", program_name, errmsg);
}

void
non_fatal VPARAMS ((const char *format, ...))
{
  VA_OPEN (args, format);
  VA_FIXEDARG (args, const char *, format);

  report (format, args);
  VA_CLOSE (args);
}

void
report (const char * format, va_list args)
{
  fflush (stdout);
  fprintf (stderr, "%s: ", program_name);
  vfprintf (stderr, format, args);
  putc ('\n', stderr);
}

void
set_default_bfd_target (void)
{
  /* The macro TARGET is defined by Makefile.  */
  const char *target = TARGET;

  if (! bfd_set_default_target (target))
    non_fatal (_("can't set BFD default target to `%s': %s"),
	   target, bfd_errmsg (bfd_get_error ()));
}

void
list_matching_formats (char **p)
{
  fflush (stdout);
  fprintf (stderr, _("%s: Matching formats:"), program_name);
  while (*p)
    fprintf (stderr, " %s", *p++);
  fputc ('\n', stderr);
}

off_t
get_file_size (const char * file_name)
{
  struct stat statbuf;
  
  if (stat (file_name, &statbuf) < 0)
    {
      if (errno == ENOENT)
	non_fatal (_("'%s': No such file"), file_name);
      else
	non_fatal (_("Warning: could not locate '%s'.  reason: %s"),
		   file_name, strerror (errno));
    }  
  else if (! S_ISREG (statbuf.st_mode))
    non_fatal (_("Warning: '%s' is not an ordinary file"), file_name);
  else if (statbuf.st_size < 0)
    non_fatal (_("Warning: '%s' has negative size, probably it is too large"),
               file_name);
  else
    return statbuf.st_size;

  return (off_t) -1;
}


/* required main def */
int
main (int argc, char **argv)
{
  return EXIT_FAILURE;
}

