#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <time.h>
#include <dlfcn.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>

#define MAX_BUF_LEN	(128)
static char arg_buf[MAX_BUF_LEN] = {0};
#define MAX_LOG_LINES	(1024)
static int log_count = 0;

FILE *log_fp;
void log_func_enter(pthread_t tid, char *func_name, char *args);
void log_func_exit(pthread_t tid, char *func_name, char *args, int ret);
const char *translate_address(const void *addr);

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
int (*orig_pthread_rwlock_init) (pthread_rwlock_t *rwlock,
					const pthread_rwlockattr_t *attr);
int (*orig_pthread_rwlock_destroy) (pthread_rwlock_t *rwlock);
int (*orig_pthread_rwlock_rdlock) (pthread_rwlock_t *rwlock);
int (*orig_pthread_rwlock_tryrdlock) (pthread_rwlock_t *rwlock);
int (*orig_pthread_rwlock_timedrdlock) (pthread_rwlock_t *rwlock,
					const struct timespec *abstime);
int (*orig_pthread_rwlock_wrlock) (pthread_rwlock_t *rwlock);
int (*orig_pthread_rwlock_trywrlock) (pthread_rwlock_t *rwlock);
int (*orig_pthread_rwlock_timedwrlock) (pthread_rwlock_t *rwlock,
					const struct timespec *abstime);
int (*orig_pthread_rwlock_unlock) (pthread_rwlock_t *rwlock);
int (*orig_pthread_spin_init) (pthread_spinlock_t *lock, int pshared);
int (*orig_pthread_spin_destroy) (pthread_spinlock_t *lock);
int (*orig_pthread_spin_lock) (pthread_spinlock_t *lock);
int (*orig_pthread_spin_trylock) (pthread_spinlock_t *lock);
int (*orig_pthread_spin_unlock) (pthread_spinlock_t *lock);
int (*orig_pthread_barrier_init) (pthread_barrier_t *barrier,
					const pthread_barrierattr_t *attr,
					unsigned int count);
int (*orig_pthread_barrier_destroy) (pthread_barrier_t *barrier);
int (*orig_pthread_barrier_wait) (pthread_barrier_t *barrier);
int (*orig_pthread_cancel) (pthread_t th);


int
pthread_create (newthread, attr, start_routine, arg)
pthread_t *newthread;
const pthread_attr_t *attr;
void *(*start_routine) (void *);
void *arg;
{
  pthread_t self = pthread_self();
  const char *func_name = translate_address(start_routine);

  sprintf(arg_buf, "(Thread%x,%p,%s,%p)", 0, attr, func_name, arg);
  log_func_enter(self, "pthread_create", arg_buf);

  int ret = orig_pthread_create(newthread, attr, start_routine, arg);
  sprintf(arg_buf, "(Thread%x,%p,%s,%p)", (unsigned int)(*newthread), attr, func_name, arg);
  log_func_exit(self, "pthread_create", arg_buf, ret);

  return ret;
}

void
pthread_exit (retval)
void *retval;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(%p)", retval);
  log_func_enter(self, "pthread_exit", arg_buf);

  orig_pthread_exit(retval);
}

int
pthread_join (threadid, thread_return)
pthread_t threadid;
void **thread_return;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Thread%x,%p->%p)", (unsigned int)threadid, thread_return, *thread_return);
  log_func_enter(self, "pthread_join", arg_buf);

  int ret = orig_pthread_join(threadid, thread_return);
  sprintf(arg_buf, "(Thread%x,%p->%p)", (unsigned int)threadid, thread_return, *thread_return);
  log_func_exit(self, "pthread_join", arg_buf, ret);

  return ret;
}

int
pthread_tryjoin_np (th, thread_return)
pthread_t th;
void **thread_return;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Thread%x,%p->%p)", (unsigned int)th, thread_return, *thread_return);
  log_func_enter(self, "pthread_tryjoin", arg_buf);

  int ret = orig_pthread_tryjoin_np(th, thread_return);
  sprintf(arg_buf, "(Thread%x,%p->%p)", (unsigned int)th, thread_return, *thread_return);
  log_func_exit(self, "pthread_tryjoin", arg_buf, ret);

  return ret;
}

int
pthread_timedjoin_np (th, thread_return, abstime)
pthread_t th;
void **thread_return;
const struct timespec *abstime;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Thread%x,%p->%p,%lld.%.9ld)", (unsigned int)th, thread_return, *thread_return, (long long)abstime->tv_sec, abstime->tv_nsec);
  log_func_enter(self, "pthread_timedjoin", arg_buf);

  int ret = orig_pthread_timedjoin_np(th, thread_return, abstime);
  sprintf(arg_buf, "(Thread%x,%p->%p,%lld.%.9ld)", (unsigned int)th, thread_return, *thread_return, (long long)abstime->tv_sec, abstime->tv_nsec);
  log_func_exit(self, "pthread_timedjoin", arg_buf, ret);

  return ret;
}

int
pthread_detach (th)
pthread_t th;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Thread%x)", (unsigned int)th);
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
  const char *mutex_name = translate_address(mutex);

  sprintf(arg_buf, "(Mutex%lx->%s,%p)", (unsigned long)mutex, mutex_name, mutexattr);
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
  const char *mutex_name = translate_address(mutex);

  sprintf(arg_buf, "(Mutex%lx->%s)", (unsigned long)mutex, mutex_name);
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
  const char *mutex_name = translate_address(mutex);

  sprintf(arg_buf, "(Mutex%lx->%s)", (unsigned long)mutex, mutex_name);
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
  const char *mutex_name = translate_address(mutex);

  sprintf(arg_buf, "(Mutex%lx->%s)", (unsigned long)mutex, mutex_name);
  log_func_enter(self, "pthread_mutex_lock", arg_buf);

  int ret = orig_pthread_mutex_lock(mutex);
  sprintf(arg_buf, "(Mutex%lx->%s)", (unsigned long)mutex, mutex_name);
  log_func_exit(self, "pthread_mutex_lock", arg_buf, ret);

  return ret;
}

int
pthread_mutex_timedlock (mutex, abstime)
pthread_mutex_t *mutex;
const struct timespec *abstime;
{
  pthread_t self = pthread_self();
  const char *mutex_name = translate_address(mutex);

  sprintf(arg_buf, "(Mutex%lx->%s,%lld.%.9ld)", (unsigned long)mutex, mutex_name, (long long)abstime->tv_sec, abstime->tv_nsec);
  log_func_enter(self, "pthread_mutex_timedlock", arg_buf);

  int ret = orig_pthread_mutex_timedlock(mutex, abstime);
  sprintf(arg_buf, "(Mutex%lx->%s,%lld.%.9ld)", (unsigned long)mutex, mutex_name, (long long)abstime->tv_sec, abstime->tv_nsec);
  log_func_exit(self, "pthread_mutex_timedlock", arg_buf, ret);

  return ret;
}

int 
pthread_mutex_unlock (mutex)
pthread_mutex_t *mutex;
{
  pthread_t self = pthread_self();
  const char *mutex_name = translate_address(mutex);

  sprintf(arg_buf, "(Mutex%lx->%s)", (unsigned long)mutex, mutex_name);
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
  const char *cond_name = translate_address(cond);

  sprintf(arg_buf, "(Cond%lx->%s,%p)", (unsigned long)cond, cond_name, cond_attr);
  log_func_enter(self, "pthread_cond_init", arg_buf);

  int ret = orig_pthread_cond_init(cond, cond_attr);
  log_func_exit(self, "pthread_cond_init", arg_buf, ret);

  return ret;
}

int pthread_cond_destroy (cond)
pthread_cond_t *cond;
{
  pthread_t self = pthread_self();
  const char *cond_name = translate_address(cond);

  sprintf(arg_buf, "(Cond%lx->%s)", (unsigned long)cond, cond_name);
  log_func_enter(self, "pthread_cond_destroy", arg_buf);

  int ret = orig_pthread_cond_destroy(cond);
  log_func_exit(self, "pthread_cond_destroy", arg_buf, ret);

  return ret;
}

int
pthread_cond_signal (cond)
pthread_cond_t *cond;
{
//  printf("test0\n");

  pthread_t self = pthread_self();

//  printf("test1\n");

  const char *cond_name = translate_address(cond);

//  printf("test2\n");


  sprintf(arg_buf, "(Cond%lx->%s)", (unsigned long)cond, cond_name);
  log_func_enter(self, "pthread_cond_signal", arg_buf);

  int ret = orig_pthread_cond_signal(cond);
  sprintf(arg_buf, "(Cond%lx->%s)", (unsigned long)cond, cond_name);
  log_func_exit(self, "pthread_cond_signal", arg_buf, ret);

  return ret;
}

int
pthread_cond_broadcast (cond)
pthread_cond_t *cond;
{
  pthread_t self = pthread_self();
  const char *cond_name = translate_address(cond);

  sprintf(arg_buf, "(Cond%lx->%s)", (unsigned long)cond, cond_name);
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
  const char *cond_name = translate_address(cond);
  const char *mutex_name = translate_address(mutex);

  sprintf(arg_buf, "(Cond%lx->%s,Mutex%lx->%s)", (unsigned long)cond, cond_name, (unsigned long)mutex, mutex_name);
  log_func_enter(self, "pthread_cond_wait", arg_buf);

  int ret = orig_pthread_cond_wait(cond, mutex);
  sprintf(arg_buf, "(Cond%lx->%s,Mutex%lx->%s)", (unsigned long)cond, cond_name, (unsigned long)mutex, mutex_name);
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
  const char *cond_name = translate_address(cond);
  const char *mutex_name = translate_address(mutex);

  sprintf(arg_buf, "(Cond%lx->%s,Mutex%lx->%s,%lld.%.9ld)", (unsigned long)cond, cond_name, (unsigned long)mutex, mutex_name, (long long)abstime->tv_sec, abstime->tv_nsec);
  log_func_enter(self, "pthread_cond_timedwait", arg_buf);

  int ret = orig_pthread_cond_timedwait(cond, mutex, abstime);
  sprintf(arg_buf, "(Cond%lx->%s,Mutex%lx->%s,%lld.%.9ld)", (unsigned long)cond, cond_name, (unsigned long)mutex, mutex_name, (long long)abstime->tv_sec, abstime->tv_nsec);
  log_func_exit(self, "pthread_cond_timedwait", arg_buf, ret);

  return ret;
}

int
pthread_rwlock_init (rwlock, attr)
pthread_rwlock_t *rwlock;
const pthread_rwlockattr_t *attr;
{
  pthread_t self = pthread_self();
  const char *rwlock_name = translate_address(rwlock);

  sprintf(arg_buf, "(RWLock%lx->%s,%p)", (unsigned long)rwlock, rwlock_name, attr);
  log_func_enter(self, "pthread_rwlock_init", arg_buf);

  int ret = orig_pthread_rwlock_init(rwlock, attr);
  log_func_exit(self, "pthread_rwlock_init", arg_buf, ret);

  return ret;
}

int
pthread_rwlock_destroy (rwlock)
pthread_rwlock_t *rwlock;
{
  pthread_t self = pthread_self();
  const char *rwlock_name = translate_address(rwlock);

  sprintf(arg_buf, "(RWLock%lx->%s)", (unsigned long)rwlock, rwlock_name);
  log_func_enter(self, "pthread_rwlock_destroy", arg_buf);

  int ret = orig_pthread_rwlock_destroy(rwlock);
  log_func_exit(self, "pthread_rwlock_destroy", arg_buf, ret);

  return ret;
}

int
pthread_rwlock_rdlock (rwlock)
pthread_rwlock_t *rwlock;
{
  pthread_t self = pthread_self();
  const char *rwlock_name = translate_address(rwlock);

  sprintf(arg_buf, "(RWLock%lx->%s)", (unsigned long)rwlock, rwlock_name);
  log_func_enter(self, "pthread_rwlock_rdlock", arg_buf);

  int ret = orig_pthread_rwlock_rdlock(rwlock);
  sprintf(arg_buf, "(RWLock%lx->%s)", (unsigned long)rwlock, rwlock_name);
  log_func_exit(self, "pthread_rwlock_rdlock", arg_buf, ret);

  return ret;
}

int
pthread_rwlock_tryrdlock (rwlock)
pthread_rwlock_t *rwlock;
{
  pthread_t self = pthread_self();
  const char *rwlock_name = translate_address(rwlock);

  sprintf(arg_buf, "(RWLock%lx->%s)", (unsigned long)rwlock, rwlock_name);
  log_func_enter(self, "pthread_rwlock_tryrdlock", arg_buf);

  int ret = orig_pthread_rwlock_tryrdlock(rwlock);
  log_func_exit(self, "pthread_rwlock_tryrdlock", arg_buf, ret);

  return ret;
}

int
pthread_rwlock_timedrdlock (rwlock, abstime)
pthread_rwlock_t *rwlock;
const struct timespec *abstime;
{
  pthread_t self = pthread_self();
  const char *rwlock_name = translate_address(rwlock);

  sprintf(arg_buf, "(RWLock%lx->%s,%lld.%.9ld)", (unsigned long)rwlock, rwlock_name, (long long)abstime->tv_sec, abstime->tv_nsec);
  log_func_enter(self, "pthread_rwlock_timedrdlock", arg_buf);

  int ret = orig_pthread_rwlock_timedrdlock(rwlock, abstime);
  sprintf(arg_buf, "(RWLock%lx->%s,%lld.%.9ld)", (unsigned long)rwlock, rwlock_name, (long long)abstime->tv_sec, abstime->tv_nsec);
  log_func_exit(self, "pthread_rwlock_timedrdlock", arg_buf, ret);

  return ret;
}

int
pthread_rwlock_wrlock (rwlock)
pthread_rwlock_t *rwlock;
{
  pthread_t self = pthread_self();
  const char *rwlock_name = translate_address(rwlock);

  sprintf(arg_buf, "(RWLock%lx->%s)", (unsigned long)rwlock, rwlock_name);
  log_func_enter(self, "pthread_rwlock_wrlock", arg_buf);

  int ret = orig_pthread_rwlock_wrlock(rwlock);
  sprintf(arg_buf, "(RWLock%lx->%s)", (unsigned long)rwlock, rwlock_name);
  log_func_exit(self, "pthread_rwlock_wrlock", arg_buf, ret);

  return ret;
}

int
pthread_rwlock_trywrlock (rwlock)
pthread_rwlock_t *rwlock;
{
  pthread_t self = pthread_self();
  const char *rwlock_name = translate_address(rwlock);

  sprintf(arg_buf, "(RWLock%lx->%s)", (unsigned long)rwlock, rwlock_name);
  log_func_enter(self, "pthread_rwlock_trywrlock", arg_buf);

  int ret = orig_pthread_rwlock_trywrlock(rwlock);
  log_func_exit(self, "pthread_rwlock_trywrlock", arg_buf, ret);

  return ret;
}

int
pthread_rwlock_timedwrlock (rwlock, abstime)
pthread_rwlock_t *rwlock;
const struct timespec *abstime;
{
  pthread_t self = pthread_self();
  const char *rwlock_name = translate_address(rwlock);

  sprintf(arg_buf, "(RWLock%lx->%s,%lld.%.9ld)", (unsigned long)rwlock, rwlock_name, (long long)abstime->tv_sec, abstime->tv_nsec);
  log_func_enter(self, "pthread_rwlock_timedwrlock", arg_buf);

  int ret = orig_pthread_rwlock_timedwrlock(rwlock, abstime);
  sprintf(arg_buf, "(RWLock%lx->%s,%lld.%.9ld)", (unsigned long)rwlock, rwlock_name, (long long)abstime->tv_sec, abstime->tv_nsec);
  log_func_exit(self, "pthread_rwlock_timedwrlock", arg_buf, ret);

  return ret;
}

int
pthread_rwlock_unlock (rwlock)
pthread_rwlock_t *rwlock;
{
  pthread_t self = pthread_self();
  const char *rwlock_name = translate_address(rwlock);

  sprintf(arg_buf, "(RWLock%lx->%s)", (unsigned long)rwlock, rwlock_name);
  log_func_enter(self, "pthread_rwlock_unlock", arg_buf);

  int ret = orig_pthread_rwlock_unlock(rwlock);
  log_func_exit(self, "pthread_rwlock_unlock", arg_buf, ret);

  return ret;
}

int
pthread_spin_init (lock, pshared)
pthread_spinlock_t *lock;
int pshared;
{
  pthread_t self = pthread_self();
  const char *lock_name = translate_address((const void*)lock);

  sprintf(arg_buf, "(Spin%lx->%s,%d)", (unsigned long)lock, lock_name, pshared);
  log_func_enter(self, "pthread_spin_init", arg_buf);

  int ret = orig_pthread_spin_init(lock, pshared);
  log_func_exit(self, "pthread_spin_init", arg_buf, ret);

  return ret;
}

int
pthread_spin_destroy (lock)
pthread_spinlock_t *lock;
{
  pthread_t self = pthread_self();
  const char *lock_name = translate_address((const void*)lock);

  sprintf(arg_buf, "(Spin%lx->%s)", (unsigned long)lock, lock_name);
  log_func_enter(self, "pthread_spin_destroy", arg_buf);

  int ret = orig_pthread_spin_destroy(lock);
  log_func_exit(self, "pthread_spin_destroy", arg_buf, ret);

  return ret;
}

int
pthread_spin_lock (lock)
pthread_spinlock_t *lock;
{
  pthread_t self = pthread_self();
  const char *lock_name = translate_address((const void*)lock);

  sprintf(arg_buf, "(Spin%lx->%s)", (unsigned long)lock, lock_name);
  log_func_enter(self, "pthread_spin_lock", arg_buf);

  int ret = orig_pthread_spin_lock(lock);
  sprintf(arg_buf, "(Spin%lx->%s)", (unsigned long)lock, lock_name);
  log_func_exit(self, "pthread_spin_lock", arg_buf, ret);

  return ret;
}

int
pthread_spin_trylock (lock)
pthread_spinlock_t *lock;
{
  pthread_t self = pthread_self();
  const char *lock_name = translate_address((const void*)lock);

  sprintf(arg_buf, "(Spin%lx->%s)", (unsigned long)lock, lock_name);
  log_func_enter(self, "pthread_spin_trylock", arg_buf);

  int ret = orig_pthread_spin_trylock(lock);
  log_func_exit(self, "pthread_spin_trylock", arg_buf, ret);

  return ret;
}

int pthread_spin_unlock (lock)
pthread_spinlock_t *lock;
{
  pthread_t self = pthread_self();
  const char *lock_name = translate_address((const void*)lock);

  sprintf(arg_buf, "(Spin%lx->%s)", (unsigned long)lock, lock_name);
  log_func_enter(self, "pthread_spin_unlock", arg_buf);

  int ret = orig_pthread_spin_unlock(lock);
  log_func_exit(self, "pthread_spin_unlock", arg_buf, ret);

  return ret;
}

int
pthread_barrier_init (barrier, attr, count)
pthread_barrier_t *barrier;
const pthread_barrierattr_t *attr;
unsigned int count;
{
  pthread_t self = pthread_self();
  const char *barrier_name = translate_address(barrier);

  sprintf(arg_buf, "(Barrier%lx->%s,%p,%u)", (unsigned long)barrier, barrier_name, attr, count);
  log_func_enter(self, "pthread_barrier_init", arg_buf);

  int ret = orig_pthread_barrier_init(barrier, attr, count);
  log_func_exit(self, "pthread_barrier_init", arg_buf, ret);

  return ret;
}

int
pthread_barrier_destroy (barrier)
pthread_barrier_t *barrier;
{
  pthread_t self = pthread_self();
  const char *barrier_name = translate_address(barrier);

  sprintf(arg_buf, "(Barrier%lx->%s)", (unsigned long)barrier, barrier_name);
  sprintf(arg_buf, "(Barrier%lx)", (unsigned long)barrier);
  log_func_enter(self, "pthread_barrier_destroy", arg_buf);

  int ret = orig_pthread_barrier_destroy(barrier);
  log_func_exit(self, "pthread_barrier_destroy", arg_buf, ret);

  return ret;
}

int
pthread_barrier_wait (barrier)
pthread_barrier_t *barrier;
{
  pthread_t self = pthread_self();
  const char *barrier_name = translate_address(barrier);

  sprintf(arg_buf, "(Barrier%lx->%s)", (unsigned long)barrier, barrier_name);
  log_func_enter(self, "pthread_barrier_wait", arg_buf);

  int ret = orig_pthread_barrier_wait(barrier);
  sprintf(arg_buf, "(Barrier%lx->%s)", (unsigned long)barrier, barrier_name);
  log_func_exit(self, "pthread_barrier_wait", arg_buf, ret);

  return ret;
}

int
pthread_cancel (th)
pthread_t th;
{
  pthread_t self = pthread_self();

  sprintf(arg_buf, "(Thread%x)", (unsigned int)th);
  log_func_enter(self, "pthread_cancel", arg_buf);

  int ret = orig_pthread_cancel(th);
  log_func_exit(self, "pthread_cancel", arg_buf, ret);

  return ret;
}


void
_init(void) 
{
  static char link[MAX_BUF_LEN] = {0};
  static char path[MAX_BUF_LEN] = {0};
  pid_t pid = getpid();
  sprintf(link, "/proc/%d/exe", pid);

  // get path to executable
  if ((readlink(link, path, MAX_BUF_LEN - 1)) == -1) {
    perror("readlink");
    exit(EXIT_FAILURE);
  }

  // open a file for logging and log program name
  log_fp = fopen("/tmp/libthreadtrace.log", "w");

  char *program_name = strrchr(path, '/');
  if (program_name != NULL)
    fprintf(log_fp, "%s\n", program_name + 1);
  else
    fprintf(log_fp, "%s\n", path);

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
  orig_pthread_rwlock_init = dlsym(RTLD_NEXT, "pthread_rwlock_init");
  orig_pthread_rwlock_destroy = dlsym(RTLD_NEXT, "pthread_rwlock_destroy");
  orig_pthread_rwlock_rdlock = dlsym(RTLD_NEXT, "pthread_rwlock_rdlock");
  orig_pthread_rwlock_tryrdlock = dlsym(RTLD_NEXT, "pthread_rwlock_tryrdlock");
  orig_pthread_rwlock_timedrdlock = dlsym(RTLD_NEXT, "pthread_rwlock_timedrdlock");
  orig_pthread_rwlock_wrlock = dlsym(RTLD_NEXT, "pthread_rwlock_wrlock");
  orig_pthread_rwlock_trywrlock = dlsym(RTLD_NEXT, "pthread_rwlock_trywrlock");
  orig_pthread_rwlock_timedwrlock = dlsym(RTLD_NEXT, "pthread_rwlock_timedwrlock");
  orig_pthread_rwlock_unlock = dlsym(RTLD_NEXT, "pthread_rwlock_unlock");
  orig_pthread_spin_init = dlsym(RTLD_NEXT, "pthread_spin_init");
  orig_pthread_spin_destroy = dlsym(RTLD_NEXT, "pthread_spin_destroy");
  orig_pthread_spin_trylock = dlsym(RTLD_NEXT, "pthread_spin_trylock");
  orig_pthread_spin_lock = dlsym(RTLD_NEXT, "pthread_spin_lock");
  orig_pthread_spin_unlock = dlsym(RTLD_NEXT, "pthread_spin_unlock");
  orig_pthread_barrier_init = dlsym(RTLD_NEXT, "pthread_barrier_init");
  orig_pthread_barrier_destroy = dlsym(RTLD_NEXT, "pthread_barrier_destroy");
  orig_pthread_barrier_wait = dlsym(RTLD_NEXT, "pthread_barrier_wait");
  orig_pthread_cancel = dlsym(RTLD_NEXT, "pthread_cancel");
}

void
_fini()
{
  fclose(log_fp);
}

void log_func_enter(pthread_t tid, char *func_name, char *args) {
  if (log_count < MAX_LOG_LINES) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts); 

    fprintf(log_fp, "%lld.%.9ld Thread%x ENTER\t%s\t%s -\n",
	    (long long)ts.tv_sec, ts.tv_nsec,
	    (unsigned int)tid, func_name, args);
    log_count++;
  }
}

void log_func_exit(pthread_t tid, char *func_name, char *args, int ret) {
  if (log_count < MAX_LOG_LINES) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts); 

    fprintf(log_fp, "%lld.%.9ld Thread%x EXIT\t%s\t%s %d\n",
	    (long long)ts.tv_sec, ts.tv_nsec,
	    (unsigned int)tid, func_name, args, ret);
    log_count++;
  }
  fflush(log_fp);
}

const char *translate_address(const void *addr) {
  Dl_info DlInfo;

  if (dladdr(addr, &DlInfo) != 0)
    return DlInfo.dli_sname;
  return NULL;
}

