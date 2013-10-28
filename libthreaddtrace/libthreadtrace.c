#include <time.h>
#include <syscall.h>
#include <execinfo.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#ifdef __cpluslpus
#  define EXTERNC extern "C" 
#else
#  define EXTERNC 
#endif

/* 
  http://pdos.csail.mit.edu/6.828/2004/lec/l2.html
 
   * x86 dictates that stack grows down
   * GCC dictates how the stack is used. 
     Contract between caller and callee on x86: 
       after call instruction: 
           %eip points at first instruction of function 
           %esp+4 points at first argument 
           %esp points at return address 
       after ret instruction: 
           %eip contains return address 
           %esp points at arguments pushed by caller 
           called function may have trashed arguments 
           %ebx contains return value (or trash if function is void) <== was %eax!
           %ecx, %edx may be trashed 
           %ebp, %ebx, %esi, %edi must contain contents from time of call 
       Terminology: 
           %eax, %ecx, %edx are "caller save" registers 
           %ebp, %ebx, %esi, %edi are "callee save" registers 
       each function has a stack frame marked by %ebp, %esp 
               +------------+   |
               | arg 2      |   \
               +------------+    >- previous function's stack frame
               | arg 1      |   /
               +------------+   |
               | ret %eip   |   /
               +============+   
               | saved %ebp |   \
        %ebp-> +------------+   |
               |            |   |
               |   local    |   \
               | variables, |    >- current function's stack frame
               |    etc.    |   /
               |            |   |
               |            |   |
        %esp-> +------------+   /

 */

/*
 * First argument's offset with respect to the frame.  Dependent on
 * optimizations made by the compiler.  The value below is the 
 * non-optimized one. 
 */
#define ARG_OFFSET     (2)
/*
 * gcc 4.1.2 && -O0 : return value is stored in the ebx register. 
 */
#define GET_EBX(var)  __asm__ __volatile__( "movl %%ebx, %0" : "=a"(var) ) 
#define SET_EBX(var)  __asm__ __volatile__( "movl %0, %%ebx" : :"a"(var) ) 

#define PROG_START_ADDR  0x08048000
#define STACK_START_ADDR 0xBFFFFFFF


#define MAX_ARGS_TO_LOG	(6)
#define MAX_BUF_LEN		(127)
#define ARG_BUF_LEN		(12*(MAX_ARGS_TO_LOG+1))

static int n_chr(const char *str, char ch);
static int is_cpp(const char *func_sig);
static char* get_args(char *buf, int len, int n_args, int *frame);

void __cyg_profile_func_enter(void *func, void *callsite)
{
	struct timespec ts;	       				/* timestamp */
    int self = 0;               			/* thread identifier */
    char func_buf[MAX_BUF_LEN + 1] = {0};	/* buffer for function signature */
    char site_buf[MAX_BUF_LEN + 1] = {0}; 	/* buffer for callsite signature */
    char arg_buf[ARG_BUF_LEN + 1] = {0}; 	/* buffer for argument values*/
	int *frame = NULL;  					/* stack frame address; for argument value retrieval */
    int n_args = 0;
    
    clock_gettime(CLOCK_REALTIME, &ts);	    	/* set timestamp to time of system clock */
    self = syscall(SYS_gettid);
	frame = (int *)__builtin_frame_address(1);  /* 'level' argument (1) specifies caller of the instrument function i.e. the function being instrumented */
    assert(frame != NULL); 
    
    /* resolve called function address to function signature */
    libtrace_resolve (func, func_buf, MAX_BUF_LEN, NULL, 0);
    /* resolve function callsite (with respect to program source) */
    libtrace_resolve (callsite, NULL, 0, site_buf, MAX_BUF_LEN);
    n_args = n_chr(func_buf, ',') + 1;	/* last arg not followed by a comma */
    n_args += is_cpp(func_buf);			/* class member functions include 'this' parameter */
    if (n_args > MAX_ARGS_TO_LOG)
        n_args = MAX_ARGS_TO_LOG;
    get_args(arg_buf, ARG_BUF_LEN, n_args, frame);

    /* print line to log */
    // TODO: specify output file
    printf("%lld.%.9ld, t%d: %s %s [from %s]\n",
        (long long)ts.tv_sec, ts.tv_nsec, self,
        func_buf, arg_buf, site_buf);
}

void __cyg_profile_func_exit(void *func, void *callsite)
{
	struct timespec ts;	       				/* timestamp */
	int self = 0;                  			/* thread identifier */
	char func_buf[MAX_BUF_LEN + 1] = {0};	/* buffer for function signature */
	char site_buf[MAX_BUF_LEN + 1] = {0};	/* buffer for callsite signature */
	long ret = 0L;							/* function return code */

    /* return codes are stored in the register %ebx (for optimizatin level -O0)
     * unfortunately, (currently assumed) return values are unavailable for -O levels >= 1 */
	GET_EBX(ret);
    clock_gettime(CLOCK_REALTIME, &ts);     /* set timestamp to time of system clock */
    self = syscall(SYS_gettid);

    /* resolve called function address to function signature */
    libtrace_resolve (func, func_buf, MAX_BUF_LEN, NULL, 0);

    /* print line to log */
    // TODO: specify output file
    printf("%lld.%.9ld, t%d: %s => %d\n",
        (long long)ts.tv_sec, ts.tv_nsec, self,
        func_buf, ret);

    SET_EBX(ret);
}

/* initializes the libtrace helper library */
void _init()  __attribute__((constructor));
void _init()
{
    const char *prog = getenv("THREADTRACE_PROGRAM"); 
    
    if (NULL == prog) {
        fprintf(stderr, 
                "The THREADTRACE_PROGRAM environment variable must be set to the "
                "program to be traced.");
        exit(EXIT_FAILURE); 
    }
    
    if (0 != libtrace_init(prog, NULL, NULL)) {
        fprintf(stderr, "libtrace_init() failed.");
        exit(EXIT_FAILURE); 
    }
}


void  _fini()  __attribute__((destructor)); 
void _fini()
{
    libtrace_close();
}

/* Number of occurences of 'ch' in 'str' */
static int n_chr(const char *str, char ch)
{
    int n = 0;
    while (*str != '\0') {
        if (*str == ch)
            n++;
        str++;
    }
    return n; 
}

/* Verifies whether function is a class member */
static int is_cpp(const char *func_sig)
{
    if (NULL == strstr(func_sig, "::"))
        return 0;
    return 1; 
}

/*A not-very-sophisticated function to print arguments. */
// TODO: Implement address lookups for function pointers
// as detected from the function signature
static char* get_args(char *buf, int len, int n_args, int *frame)
{
    int i; 
    int offset;
    
    memset(buf, 0, len); 
    
    snprintf(buf, len, "("); 
    offset = 1; 
    for (i = 0; i < n_args && offset < len; i++) {
        offset += snprintf(buf + offset, len - offset,
            "%d%s", *(frame + ARG_OFFSET + i),
            i == (n_args - 1) ? ")" : ", ");
    }

    return buf;
}