#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <time.h>
#include <dlfcn.h>
#include <pthread.h>

/*
pthread_create
pthread_exit
pthread_join
pthread_tryjoin
pthread_timedjoin
pthread_mutex_init
pthread_mutex_destroy
pthread_mutex_lock
pthread_mutex_trylock
pthread_mutex_timedlock
pthread_mutex_unlock
pthread_rwlock_init
pthread_rwlock_destroy
pthread_rwlock_rdlock
pthread_rwlock_wrlock
pthread_rwlock_tryrdlock
pthread_rwlock_trywrlock
pthread_rwlock_timedrdlock
pthread_rwlock_timedwrlock
pthread_rwlock_unlock
pthread_cond_init
pthread_cond_destroy
pthread_cond_wait
pthread_cond_timedwait
pthread_cond_signal
pthread_cond_broadcast
pthread_spin_init
pthread_spin_destroy
pthread_spin_lock
pthread_spin_trylock
pthread_spin_unlock
pthread_barrier_init
pthread_barrier_destroy
pthread_barrier_wait
pthread_cancel
*/

char arg_buf[128];
FILE *threadtrace_fp;

// Pointers to the original pthread functions
int (*orig_pthread_create)(pthread_t *newthread, 
			     const pthread_attr_t *attr,
			     void *(*start_routine) (void *),
			     void *arg);
int (*orig_pthread_join)(pthread_t threadid, 
			   void **thread_return);
int (*orig_pthread_mutex_lock)(pthread_mutex_t * mutex);
int (*orig_pthread_mutex_unlock)(pthread_mutex_t * mutex);

// Forward declarations
void log_func_enter(pthread_t tid, char *func_name, char *args);
void log_func_exit(pthread_t tid, char *func_name, char *args, int ret);

int
pthread_create (newthread, attr, start_routine, arg)
pthread_t *newthread;
const pthread_attr_t *attr;
void *(*start_routine) (void *);
void *arg;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(%u, %p, %p, %p)", 0, attr, start_routine, arg);
  log_func_enter(self, "pthread_create", arg_buf);

  int ret = orig_pthread_create(newthread, attr, start_routine, arg);

  sprintf(arg_buf, "(%u, %p, %p, %p)", (unsigned int)(*newthread), attr, start_routine, arg);
  log_func_exit(self, "pthread_create", arg_buf, ret);

  return ret;
}

int
pthread_join (threadid, thread_return)
pthread_t threadid;
void **thread_return;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(%u, %p)", (unsigned int)threadid, thread_return);
  log_func_enter(self, "pthread_join", arg_buf);  
  
  int ret = orig_pthread_join(threadid, thread_return);
  log_func_exit(self, "pthread_join", arg_buf, ret);

  return ret;
}

int 
pthread_mutex_lock (mutex)
pthread_mutex_t * mutex;
{
  struct timespec ts;
  int self = pthread_self();
  clock_gettime(CLOCK_REALTIME, &ts);
    
  fprintf(threadtrace_fp, "%lld.%.9ld, t%d: %s\n",
	  (long long)ts.tv_sec, ts.tv_nsec, self, "pthread_mutex_lock");

  return orig_pthread_mutex_lock(mutex);
}

int 
pthread_mutex_unlock (mutex)
pthread_mutex_t * mutex;
{
  struct timespec ts;
  int self = pthread_self();
  clock_gettime(CLOCK_REALTIME, &ts);
  
  fprintf(threadtrace_fp, "%lld.%.9ld, t%d: %s\n",
	  (long long)ts.tv_sec, ts.tv_nsec, self, "pthread_mutex_unlock");

  return orig_pthread_mutex_unlock(mutex);
}

void
_init(void) 
{
  // Open a file for logging
  threadtrace_fp = fopen("threadtrace.log", "w");
  orig_pthread_create = dlsym(RTLD_NEXT, "pthread_create");
  orig_pthread_join = dlsym(RTLD_NEXT, "pthread_join");
  orig_pthread_mutex_lock = dlsym(RTLD_NEXT, "pthread_mutex_lock");
  orig_pthread_mutex_unlock = dlsym(RTLD_NEXT, "pthread_mutex_unlock");
}

void
_fini()
{
  fclose(threadtrace_fp);
}

void log_func_enter(pthread_t tid, char *func_name, char *args) 
{
  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts); 

  fprintf(threadtrace_fp, "%lld.%.9ld T%u ENTER %s %s\n",
	  (long long)ts.tv_sec, ts.tv_nsec,
	  (unsigned int)tid, func_name, args);
}

void log_func_exit(pthread_t tid, char *func_name, char *args, int ret) 
{
  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts); 

  fprintf(threadtrace_fp, "%lld.%.9ld T%u EXIT %s %s %d\n",
	  (long long)ts.tv_sec, ts.tv_nsec,
	  (unsigned int)tid, func_name, args, ret);
}
