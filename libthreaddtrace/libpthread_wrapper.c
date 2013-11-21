#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <time.h>
#include <dlfcn.h>
#include <pthread.h>

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
  int self = 0;
  clock_gettime(CLOCK_REALTIME, &ts);
  self = syscall(SYS_gettid);
 
  fprintf(threadtrace_fp, "%lld.%.9ld, t%d: %s\n",
	  (long long)ts.tv_sec, ts.tv_nsec, self, "pthread_create");

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
