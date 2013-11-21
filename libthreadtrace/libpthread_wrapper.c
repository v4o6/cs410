#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <time.h>
#include <dlfcn.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>

#include "libtrace.h"

/*
pthread_rwlock_init
pthread_rwlock_destroy
pthread_rwlock_rdlock
pthread_rwlock_wrlock
pthread_rwlock_tryrdlock
pthread_rwlock_trywrlock
pthread_rwlock_timedrdlock
pthread_rwlock_timedwrlock
pthread_rwlock_unlock
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

FILE *log_fp;

#define MAX_BUF_LEN	(128)
static char func_buf[MAX_BUF_LEN] = {0};
static char arg_buf[MAX_BUF_LEN] = {0};

void log_func_enter(pthread_t tid, char *func_name, char *args);
void log_func_exit(pthread_t tid, char *func_name, char *args, int ret);


int (*orig_pthread_create) (pthread_t *newthread, 
			     const pthread_attr_t *attr,
			     void *(*start_routine) (void *),
			     void *arg);
void (*orig_pthread_exit) (void *retval);
int (*orig_pthread_join) (pthread_t threadid, 
			   void **thread_return);
int (*orig_pthread_tryjoin_np) (pthread_t th, void **thread_return);
int (*orig_pthread_timedjoin_np) (pthread_t th, void **thread_return,
				 const struct timespec *abstime);
int (*orig_pthread_detach) (pthread_t th);
int (*orig_pthread_mutex_init) (pthread_mutex_t *mutex,
			       const pthread_mutexattr_t *mutexattr);
int (*orig_pthread_mutex_destroy) (pthread_mutex_t *mutex);
int (*orig_pthread_mutex_trylock) (pthread_mutex_t *mutex);
int (*orig_pthread_mutex_lock) (pthread_mutex_t *mutex);
int (*orig_pthread_mutex_timedlock) (pthread_mutex_t *mutex,
				    const struct timespec *abstime);
int (*orig_pthread_mutex_unlock) (pthread_mutex_t *mutex);
int (*orig_pthread_cond_init) (pthread_cond_t *cond,
			      const pthread_condattr_t *cond_attr);
int (*orig_pthread_cond_destroy) (pthread_cond_t *cond);
int (*orig_pthread_cond_signal) (pthread_cond_t *cond);
int (*orig_pthread_cond_broadcast) (pthread_cond_t *cond);
int (*orig_pthread_cond_wait) (pthread_cond_t *cond,
			      pthread_mutex_t *mutex);
int (*orig_pthread_cond_timedwait) (pthread_cond_t *cond,
				   pthread_mutex_t *mutex,
				   const struct timespec *abstime);


int
pthread_create (newthread, attr, start_routine, arg)
pthread_t *newthread;
const pthread_attr_t *attr;
void *(*start_routine) (void *);
void *arg;
{
  pthread_t self = pthread_self();
  libtrace_translate_addresses (start_routine, func_buf, MAX_BUF_LEN, NULL, 0);

  sprintf(arg_buf, "(Thread%u,%p,%s,%p)", 0, attr, func_buf, arg);
  log_func_enter(self, "pthread_create", arg_buf);

  int ret = orig_pthread_create(newthread, attr, start_routine, arg);
  sprintf(arg_buf, "(Thread%u,%p,%s,%p)", (unsigned int)(*newthread), attr, func_buf, arg);
  log_func_exit(self, "pthread_create", arg_buf, ret);

  return ret;
}

void
pthread_exit (void *retval)
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(%p)", retval);
  log_func_enter(self, "pthread_exit", arg_buf);

  orig_pthread_exit(retval);
  log_func_exit(self, "pthread_exit", arg_buf, 0);
}

int
pthread_join (threadid, thread_return)
pthread_t threadid;
void **thread_return;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Thread%u,%p)", (unsigned int)threadid, thread_return);
  log_func_enter(self, "pthread_join", arg_buf);

  int ret = orig_pthread_join(threadid, thread_return);
  log_func_exit(self, "pthread_join", arg_buf, ret);

  return ret;
}

int
pthread_tryjoin_np (th, thread_return)
pthread_t th;
void **thread_return;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Thread%u,%p)", (unsigned int)th, thread_return);
  log_func_enter(self, "pthread_tryjoin_np", arg_buf);

  int ret = orig_pthread_tryjoin_np(th, thread_return);
  log_func_exit(self, "pthread_tryjoin_np", arg_buf, ret);

  return ret;
}

int
pthread_timedjoin_np (th, thread_return, abstime)
pthread_t th;
void **thread_return;
const struct timespec *abstime;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Thread%u,%p,%lld.%.9ld)", (unsigned int)th, thread_return,(long long)abstime->tv_sec, abstime->tv_nsec);
  log_func_enter(self, "pthread_timedjoin_np", arg_buf);

  int ret = orig_pthread_timedjoin_np(th, thread_return, abstime);
  log_func_exit(self, "pthread_timedjoin_np", arg_buf, ret);

  return ret;
}

int
pthread_detach (th)
pthread_t th;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Thread%u)", (unsigned int)th);
  log_func_enter(self, "pthread_detach", arg_buf);

  int ret = orig_pthread_detach(th);
  log_func_exit(self, "pthread_detach", arg_buf, ret);

  return ret;
}

int
pthread_mutex_init (mutex, mutexattr)
pthread_mutex_t *mutex;
const pthread_mutexattr_t *mutexattr;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Mutex%lu,%p)", (unsigned long)mutex, mutexattr);
  log_func_enter(self, "pthread_mutex_init", arg_buf);

  int ret = orig_pthread_mutex_init(mutex, mutexattr);
  log_func_exit(self, "pthread_mutex_init", arg_buf, ret);

  return ret;
}

int
pthread_mutex_destroy (mutex)
pthread_mutex_t *mutex;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Mutex%lu)", (unsigned long)mutex);
  log_func_enter(self, "pthread_mutex_destroy", arg_buf);

  int ret = orig_pthread_mutex_destroy(mutex);
  log_func_exit(self, "pthread_mutex_destroy", arg_buf, ret);

  return ret;
}

int
pthread_mutex_trylock (mutex)
pthread_mutex_t *mutex;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Mutex%lu)", (unsigned long)mutex);
  log_func_enter(self, "pthread_mutex_trylock", arg_buf);

  int ret = orig_pthread_mutex_trylock(mutex);
  log_func_exit(self, "pthread_mutex_trylock", arg_buf, ret);

  return ret;
}

int 
pthread_mutex_lock (mutex)
pthread_mutex_t *mutex;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Mutex%lu)", (unsigned long)mutex);
  log_func_enter(self, "pthread_mutex_lock", arg_buf);

  int ret = orig_pthread_mutex_lock(mutex);
  log_func_exit(self, "pthread_mutex_lock", arg_buf, ret);

  return ret;
}

int
pthread_mutex_timedlock (mutex, abstime)
pthread_mutex_t *mutex;
const struct timespec *abstime;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Mutex%lu,%lld.%.9ld)", (unsigned long)mutex, (long long)abstime->tv_sec, abstime->tv_nsec);
  log_func_enter(self, "pthread_timedlock", arg_buf);

  int ret = orig_pthread_mutex_timedlock(mutex, abstime);
  log_func_exit(self, "pthread_timedlock", arg_buf, ret);

  return ret;
}

int 
pthread_mutex_unlock (mutex)
pthread_mutex_t *mutex;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Mutex%lu)", (unsigned long)mutex);
  log_func_enter(self, "pthread_mutex_unlock", arg_buf);

  int ret = orig_pthread_mutex_unlock(mutex);
  log_func_exit(self, "pthread_mutex_unlock", arg_buf, ret);

  return ret;

}

int
pthread_cond_init (cond, cond_attr)
pthread_cond_t *cond;
const pthread_condattr_t *cond_attr;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Cond%lu,%p)", (unsigned long)cond, cond_attr);
  log_func_enter(self, "pthread_cond_init", arg_buf);

  int ret = orig_pthread_cond_init(cond, cond_attr);
  log_func_exit(self, "pthread_cond_init", arg_buf, ret);

  return ret;
}

int pthread_cond_destroy (cond)
pthread_cond_t *cond;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Cond%lu)", (unsigned long)cond);
  log_func_enter(self, "pthread_cond_destroy", arg_buf);

  int ret = orig_pthread_cond_destroy(cond);
  log_func_exit(self, "pthread_cond_destroy", arg_buf, ret);

  return ret;
}

int
pthread_cond_signal (cond)
pthread_cond_t *cond;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Cond%lu)", (unsigned long)cond);
  log_func_enter(self, "pthread_cond_signal", arg_buf);

  int ret = orig_pthread_cond_signal(cond);
  log_func_exit(self, "pthread_cond_signal", arg_buf, ret);

  return ret;
}

int
pthread_cond_broadcast (cond)
pthread_cond_t *cond;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Cond%lu)", (unsigned long)cond);
  log_func_enter(self, "pthread_cond_broadcast", arg_buf);

  int ret = orig_pthread_cond_broadcast(cond);
  log_func_exit(self, "pthread_cond_broadcast", arg_buf, ret);

  return ret;
}

int
pthread_cond_wait (cond, mutex)
pthread_cond_t *cond;
pthread_mutex_t *mutex;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Cond%lu,Mutex%lu)", (unsigned long)cond, (unsigned long)mutex);
  log_func_enter(self, "pthread_cond_wait", arg_buf);

  int ret = orig_pthread_cond_wait(cond, mutex);
  log_func_exit(self, "pthread_cond_wait", arg_buf, ret);

  return ret;
}


int
pthread_cond_timedwait (cond, mutex, abstime)
pthread_cond_t *cond;
pthread_mutex_t *mutex;
const struct timespec *abstime;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Cond%lu,Mutex%lu,%lld.%.9ld)", (unsigned long)cond, (unsigned long)mutex, (long long)abstime->tv_sec, abstime->tv_nsec);
  log_func_enter(self, "pthread_cond_timedwait", arg_buf);

  int ret = orig_pthread_cond_timedwait(cond, mutex, abstime);
  log_func_exit(self, "pthread_cond_timedwait", arg_buf, ret);

  return ret;
}


void
_init(void) 
{
  char link[MAX_BUF_LEN] = {0};
  char path[MAX_BUF_LEN] = {0};
  pid_t pid = getpid();
  sprintf(link, "/proc/%d/exe", pid);

  if ((readlink(link, path, MAX_BUF_LEN - 1)) == -1) {
    perror("readlink");
    exit(EXIT_FAILURE);
  }

  if (0 != libtrace_init(path, NULL, NULL)) {
    fprintf(stderr, "libtrace_init() failed.");
    exit(EXIT_FAILURE); 
  }

  // open a file for logging and log program name
  log_fp = fopen("threadtrace.log", "w");

  char *program_name = strrchr(path, '/');
  if (program_name != NULL)
    fprintf(log_fp, "program_name: %s\n", program_name + 1);
  else
    fprintf(log_fp, "program_name: %s\n", path);

  // delink targeted pthread functions to override them with our own
  orig_pthread_create = dlsym(RTLD_NEXT, "pthread_create");
  orig_pthread_exit = dlsym(RTLD_NEXT, "pthread_exit");
  orig_pthread_join = dlsym(RTLD_NEXT, "pthread_join");
  orig_pthread_tryjoin_np = dlsym(RTLD_NEXT, "pthread_tryjoin_np");
  orig_pthread_timedjoin_np = dlsym(RTLD_NEXT, "pthread_timedjoin_np");
  orig_pthread_detach = dlsym(RTLD_NEXT, "pthread_detach");
  orig_pthread_mutex_init = dlsym(RTLD_NEXT, "pthread_mutex_init");
  orig_pthread_mutex_destroy = dlsym(RTLD_NEXT, "pthread_mutex_destroy");
  orig_pthread_mutex_trylock = dlsym(RTLD_NEXT, "pthread_mutex_trylock");
  orig_pthread_mutex_lock = dlsym(RTLD_NEXT, "pthread_mutex_lock");
  orig_pthread_mutex_timedlock = dlsym(RTLD_NEXT, "pthread_mutex_timedlock");
  orig_pthread_mutex_unlock = dlsym(RTLD_NEXT, "pthread_mutex_unlock");
  orig_pthread_cond_init = dlsym(RTLD_NEXT, "pthread_cond_init");
  orig_pthread_cond_destroy = dlsym(RTLD_NEXT, "pthread_cond_destroy");
  orig_pthread_cond_signal = dlsym(RTLD_NEXT, "pthread_cond_signal");
  orig_pthread_cond_broadcast = dlsym(RTLD_NEXT, "pthread_cond_broadcast");
  orig_pthread_cond_wait = dlsym(RTLD_NEXT, "pthread_cond_wait");
  orig_pthread_cond_timedwait = dlsym(RTLD_NEXT, "pthread_cond_timedwait");
}

void
_fini()
{
  libtrace_close();
  fclose(log_fp);
}

void log_func_enter(pthread_t tid, char *func_name, char *args) {
  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts); 

  fprintf(log_fp, "%lld.%.9ld Thread%u ENTER %s %s -\n",
	  (long long)ts.tv_sec, ts.tv_nsec,
	  (unsigned int)tid, func_name, args);
}

void log_func_exit(pthread_t tid, char *func_name, char *args, int ret) {
  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts); 

  fprintf(log_fp, "%lld.%.9ld Thread%u EXIT %s %s %d\n",
	  (long long)ts.tv_sec, ts.tv_nsec,
	  (unsigned int)tid, func_name, args, ret);
}
