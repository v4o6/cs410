gcc -Wall -fPIC -DPIC -c libpthread_wrapper.c
ld -shared -o libpthread_wrapper.so libpthread_wrapper.o -ldl
LD_PRELOAD=./libpthread_wrapper.so ./pc

#export THREADTRACE_PROGRAM=./pthreadDriver
#LD_PRELOAD=./libthreadtrace.so ./pthreadDriver
#export THREADTRACE_PROGRAM=./pc
#LD_PRELOAD=./libthreadtrace.so ./pc
