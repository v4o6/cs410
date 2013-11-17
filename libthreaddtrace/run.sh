# The path to the custom glibc library needs to be changed
if [ ! -L libpthread.so.0 ]; then
  ln -s /home/ras/cs410/glibc-install/lib/libpthread-2.18.90.so libpthread.so.0
fi

export LD_LIBRARY_PATH=.
export THREADTRACE_PROGRAM=./pthreadDriver
LD_PRELOAD=./libthreadtrace.so ./pthreadDriver
