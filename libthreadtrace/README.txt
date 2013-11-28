Wrapper library for libpthreads.

Test programs: thread-pool-server producer-consumer

Compile libpthread_wrapper.so and the test program by typing 'make'.  To change the targeted test program, modify the $TARGET and $TARGET_SRC variables in Makefile to point to the appropriate files. To run the test program with libpthread_wrapper.so and generate a log file, type 'make run'.

To run libpthread_wrapper.so with an arbitrary pthread program (including arbitrary arguments) and generate a log file, type './run.sh <PROGRAM PATH> <PROGRAM ARGS>'.

