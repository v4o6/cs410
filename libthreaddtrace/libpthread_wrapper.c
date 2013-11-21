#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <time.h>
#include <dlfcn.h>
#include <pthread.h>

/* List of pthread library calls to instrument
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


FILE *threadtrace_fp;

int (*orig_pthread_create)(pthread_t *newthread, 
			     const pthread_attr_t *attr,
			     void *(*start_routine) (void *),
			     void *arg);
int (*orig_pthread_join)(pthread_t threadid, 
			   void **thread_return);
int (*orig_pthread_mutex_lock)(pthread_mutex_t * mutex);
int (*orig_pthread_mutex_unlock)(pthread_mutex_t * mutex);


int
pthread_create (newthread, attr, start_routine, arg)
pthread_t *newthread;
const pthread_attr_t *attr;
void *(*start_routine) (void *);
void *arg;
{
  struct timespec ts;
  pthread_t self = (pthread_t)0;
  char arg_buf[256];

  clock_gettime(CLOCK_REALTIME, &ts);
  self = pthread_self();
  sprintf(arg_buf, "(%d, %p, %p, %p)", *newthread, attr, start_routine, arg);
 
  fprintf(threadtrace_fp, "%lld.%.9ld, t%d: %s %s\n",
	  (long long)ts.tv_sec, ts.tv_nsec, self, "pthread_create", arg_buf);

  return orig_pthread_create(newthread, attr, start_routine, arg);
}

int
pthread_join (threadid, thread_return)
pthread_t threadid;
void **thread_return;
{
  struct timespec ts;
  int self = 0;
  clock_gettime(CLOCK_REALTIME, &ts);
  self = syscall(SYS_gettid);

  fprintf(threadtrace_fp, "%lld.%.9ld, t%d: %s\n",
	  (long long)ts.tv_sec, ts.tv_nsec, self, "pthread_join");
  
  return orig_pthread_join(threadid, thread_return);
}

int 
pthread_mutex_lock (mutex)
pthread_mutex_t * mutex;
{
  struct timespec ts;
  int self = 0;
  clock_gettime(CLOCK_REALTIME, &ts);
  self = syscall(SYS_gettid);
  
  fprintf(threadtrace_fp, "%lld.%.9ld, t%d: %s\n",
	  (long long)ts.tv_sec, ts.tv_nsec, self, "pthread_mutex_lock");

  return orig_pthread_mutex_lock(mutex);
}

int 
pthread_mutex_unlock (mutex)
pthread_mutex_t * mutex;
{
  struct timespec ts;
  int self = 0;
  clock_gettime(CLOCK_REALTIME, &ts);
  self = syscall(SYS_gettid);

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
